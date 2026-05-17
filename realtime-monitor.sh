#!/bin/bash

################################################################################
# K3s 클러스터 실시간 모니터링 대시보드
# 사용법: ./realtime-monitor.sh [업데이트 간격(초)]
# 예: ./realtime-monitor.sh 5
################################################################################

UPDATE_INTERVAL=${1:-10}  # 기본 10초

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# 함수: 진행 바 그리기
draw_progress_bar() {
    local current=$1
    local total=$2
    local width=20
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    
    # 색상 선택
    if [ "$percentage" -gt 80 ]; then
        color=$RED
    elif [ "$percentage" -gt 60 ]; then
        color=$YELLOW
    else
        color=$GREEN
    fi
    
    printf "${color}["
    for ((i = 0; i < filled; i++)); do printf "="; done
    for ((i = filled; i < width; i++)); do printf " "; done
    printf "]${NC} %3d%%\n" "$percentage"
}

# 함수: 상태 심볼
get_status_symbol() {
    local status=$1
    if [[ "$status" == "Ready" ]]; then
        echo "✓"
    elif [[ "$status" == "Running" ]]; then
        echo "✓"
    elif [[ "$status" == "Pending" ]]; then
        echo "⏳"
    elif [[ "$status" == "Failed" ]]; then
        echo "✗"
    elif [[ "$status" == "Error" ]]; then
        echo "✗"
    else
        echo "?"
    fi
}

################################################################################
# 메인 루프
################################################################################

# 종료 신호 처리
trap 'echo -e "\n${CYAN}모니터링 중단됨${NC}"; exit 0' SIGINT SIGTERM

while true; do
    # 화면 초기화
    clear
    
    # 헤더
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}          K3s 클러스터 실시간 모니터링 대시보드                 ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  업데이트 간격: ${UPDATE_INTERVAL}초 | 시간: $(date '+%H:%M:%S')                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 1. 클러스터 정보
    echo -e "${MAGENTA}━━━ 클러스터 정보 ━━━${NC}"
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}✗ 클러스터에 연결할 수 없습니다!${NC}"
        echo "Ctrl+C로 종료하세요"
        sleep $UPDATE_INTERVAL
        continue
    fi
    
    VERSION=$(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')
    echo -e "K3s 버전: ${GREEN}$VERSION${NC}"
    
    CLUSTER_NAME=$(kubectl config current-context 2>/dev/null | cut -d'/' -f1)
    echo -e "컨텍스트: ${GREEN}$CLUSTER_NAME${NC}"
    echo ""
    
    # 2. 노드 상태
    echo -e "${MAGENTA}━━━ 노드 상태 ━━━${NC}"
    
    NODES=$(kubectl get nodes --no-headers 2>/dev/null)
    READY_COUNT=$(echo "$NODES" | grep -c "Ready")
    NOT_READY_COUNT=$(echo "$NODES" | grep -c "NotReady")
    TOTAL_NODES=$(echo "$NODES" | wc -l)
    
    # 노드 요약
    if [ "$NOT_READY_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓ 모든 노드 Ready${NC} ($READY_COUNT/$TOTAL_NODES)"
    else
        echo -e "${RED}✗ 일부 노드 문제${NC} (Ready: $READY_COUNT, NotReady: $NOT_READY_COUNT)"
    fi
    
    # 각 노드별 상태
    echo "$NODES" | awk '{
        status = $2
        if (status ~ /Ready/) {
            color = "\033[0;32m"
            symbol = "✓"
        } else {
            color = "\033[0;31m"
            symbol = "✗"
        }
        printf "  %s %s%-15s%s %-10s Age:%s\n", symbol, color, $1, "\033[0m", status, $5
    }' | head -10
    
    echo ""
    
    # 3. 노드 리소스 사용량
    echo -e "${MAGENTA}━━━ 노드 리소스 사용량 ━━━${NC}"
    
    if kubectl top nodes &> /dev/null; then
        kubectl top nodes --no-headers 2>/dev/null | awk '{
            cpu_usage = $2
            cpu_total = $3
            mem_usage = $4
            mem_total = $5
            
            # CPU 색상
            cpu_pct = (cpu_usage / cpu_total) * 100
            if (cpu_pct > 80) cpu_color = "\033[0;31m"
            else if (cpu_pct > 60) cpu_color = "\033[1;33m"
            else cpu_color = "\033[0;32m"
            
            # 메모리 색상
            mem_pct = (mem_usage / mem_total) * 100
            if (mem_pct > 80) mem_color = "\033[0;31m"
            else if (mem_pct > 60) mem_color = "\033[1;33m"
            else mem_color = "\033[0;32m"
            
            printf "%-15s: CPU: %3dm/%3dm (%.0f%%) | MEM: %4dMi/%4dMi (%.0f%%)\n", \
                $1, cpu_usage, cpu_total, cpu_pct, mem_usage, mem_total, mem_pct
        }'
    else
        echo "⏳ 메트릭 서버 초기화 중... (1분 이상 필요)"
    fi
    echo ""
    
    # 4. 파드 상태
    echo -e "${MAGENTA}━━━ 파드 상태 (모든 네임스페이스) ━━━${NC}"
    
    PODS=$(kubectl get pods -A --no-headers 2>/dev/null)
    RUNNING=$(echo "$PODS" | grep -c "Running" || echo 0)
    PENDING=$(echo "$PODS" | grep -c "Pending" || echo 0)
    FAILED=$(echo "$PODS" | grep -c "Failed" || echo 0)
    ERRORED=$(echo "$PODS" | grep -c "CrashLoop\|Error" || echo 0)
    TOTAL_PODS=$((RUNNING + PENDING + FAILED + ERRORED))
    
    echo -n "상태: "
    echo -n -e "${GREEN}Running: $RUNNING${NC} "
    if [ "$PENDING" -gt 0 ]; then
        echo -n -e "${YELLOW}Pending: $PENDING${NC} "
    fi
    if [ "$FAILED" -gt 0 ]; then
        echo -n -e "${RED}Failed: $FAILED${NC} "
    fi
    if [ "$ERRORED" -gt 0 ]; then
        echo -n -e "${RED}Error: $ERRORED${NC} "
    fi
    echo ""
    echo "합계: $TOTAL_PODS개"
    
    # 문제 파드 표시
    if [ "$FAILED" -gt 0 ] || [ "$ERRORED" -gt 0 ]; then
        echo -e "${RED}문제 파드:${NC}"
        kubectl get pods -A --no-headers 2>/dev/null | grep -E "Failed|CrashLoop|Error" | \
            awk '{printf "  ✗ %-25s %-40s %s\n", $1, $2, $3}' | head -5
    fi
    echo ""
    
    # 5. TOP 리소스 사용 파드
    echo -e "${MAGENTA}━━━ TOP CPU 사용 파드 ━━━${NC}"
    
    if kubectl top pods -A &> /dev/null; then
        kubectl top pods -A --no-headers 2>/dev/null | sort -k3 -nr | head -3 | \
            awk '{printf "%-25s %-35s CPU: %4s\n", $1, $2, $3}'
    else
        echo "⏳ 메트릭 수집 중..."
    fi
    echo ""
    
    # 6. TOP 메모리 사용 파드
    echo -e "${MAGENTA}━━━ TOP 메모리 사용 파드 ━━━${NC}"
    
    if kubectl top pods -A &> /dev/null; then
        kubectl top pods -A --no-headers 2>/dev/null | sort -k4 -nr | head -3 | \
            awk '{printf "%-25s %-35s MEM: %5s\n", $1, $2, $4}'
    else
        echo "⏳ 메트릭 수집 중..."
    fi
    echo ""
    
    # 7. 최근 이벤트
    echo -e "${MAGENTA}━━━ 최근 이벤트 (Warning/Error) ━━━${NC}"
    
    EVENTS=$(kubectl get events -A --sort-by='.lastTimestamp' 2>/dev/null | \
             grep -E "Warning|Error" | tail -3)
    
    if [ -z "$EVENTS" ]; then
        echo -e "${GREEN}최근 경고/에러 없음${NC}"
    else
        echo "$EVENTS" | while read line; do
            NS=$(echo "$line" | awk '{print $1}')
            OBJ=$(echo "$line" | awk '{print $3}')
            REASON=$(echo "$line" | awk '{print $4}')
            echo -e "  ${RED}✗${NC} [$NS] $OBJ: $REASON"
        done
    fi
    echo ""
    
    # 8. 시스템 파드
    echo -e "${MAGENTA}━━━ 시스템 파드 (kube-system) ━━━${NC}"
    
    SYS_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null)
    SYS_RUNNING=$(echo "$SYS_PODS" | grep -c "Running" || echo 0)
    SYS_FAILED=$(echo "$SYS_PODS" | grep -c "Failed\|Error\|CrashLoop" || echo 0)
    
    if [ "$SYS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}✓ 정상${NC} ($SYS_RUNNING/$(echo "$SYS_PODS" | wc -l))"
    else
        echo -e "${RED}✗ 문제 있음${NC} ($SYS_RUNNING 실행 중, $SYS_FAILED 문제)"
    fi
    echo ""
    
    # 9. 건강도 점수
    echo -e "${MAGENTA}━━━ 클러스터 건강도 ━━━${NC}"
    
    HEALTH=100
    
    # 노드 상태
    if [ "$NOT_READY_COUNT" -gt 0 ]; then
        HEALTH=$((HEALTH - 30))
    fi
    
    # 파드 상태
    if [ "$FAILED" -gt 0 ] || [ "$ERRORED" -gt 0 ]; then
        HEALTH=$((HEALTH - 20))
    fi
    
    # 리소스 부족
    CPU_HIGH=$(kubectl top nodes --no-headers 2>/dev/null | awk '{if($2/$3*100>80) print 1}' | wc -l)
    if [ "$CPU_HIGH" -gt 0 ]; then
        HEALTH=$((HEALTH - 10))
    fi
    
    # 건강도 표시
    if [ "$HEALTH" -ge 90 ]; then
        COLOR=$GREEN
        STATUS="정상"
    elif [ "$HEALTH" -ge 70 ]; then
        COLOR=$YELLOW
        STATUS="주의"
    else
        COLOR=$RED
        STATUS="위험"
    fi
    
    echo -e "상태: ${COLOR}$STATUS${NC} | 점수: ${COLOR}$HEALTH/100${NC}"
    
    # 10. 하단 정보
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Ctrl+C${NC}로 종료 | ${UPDATE_INTERVAL}초 마다 업데이트"
    echo ""
    
    # 대기
    sleep $UPDATE_INTERVAL
done
