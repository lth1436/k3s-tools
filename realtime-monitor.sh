#!/bin/bash

# K3s 클러스터 실시간 모니터링
# 사용법: ./realtime-monitor.sh [초]

UPDATE_INTERVAL=${1:-10}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

trap 'echo -e "\n${CYAN}모니터링 중단${NC}"; exit 0' SIGINT SIGTERM

while true; do
    clear
    
    # 헤더
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}     K3s 클러스터 실시간 모니터링 대시보드"
    echo -e "${CYAN}║${NC}  업데이트: ${UPDATE_INTERVAL}초 | 시간: $(date '+%H:%M:%S')"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 1. 클러스터 정보
    echo -e "${MAGENTA}━━━ 클러스터 정보 ━━━${NC}"
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}✗ 클러스터 연결 불가${NC}"
        sleep $UPDATE_INTERVAL
        continue
    fi
    
    VERSION=$(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')
    CONTEXT=$(kubectl config current-context 2>/dev/null)
    echo -e "K3s 버전: ${GREEN}$VERSION${NC}"
    echo -e "컨텍스트: ${GREEN}$CONTEXT${NC}"
    echo ""
    
    # 2. 노드 상태
    echo -e "${MAGENTA}━━━ 노드 상태 ━━━${NC}"
    
    NODES=$(kubectl get nodes --no-headers 2>/dev/null)
    READY_COUNT=$(echo "$NODES" | grep -c "Ready")
    NOT_READY_COUNT=$(echo "$NODES" | grep -c "NotReady")
    TOTAL_NODES=$(echo "$NODES" | wc -l)
    
    if [ "$NOT_READY_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓ 모든 노드 Ready${NC} ($READY_COUNT/$TOTAL_NODES)"
    else
        echo -e "${RED}✗ 문제 있음${NC} (Ready: $READY_COUNT, NotReady: $NOT_READY_COUNT)"
    fi
    
    echo "$NODES" | awk '{
        status = $2
        color = (status ~ /Ready/) ? "\033[0;32m" : "\033[0;31m"
        symbol = (status ~ /Ready/) ? "✓" : "✗"
        printf "  %s %s%-15s%s %-10s\n", symbol, color, $1, "\033[0m", status
    }'
    echo ""
    
    # 3. 리소스 사용량
    echo -e "${MAGENTA}━━━ 노드 리소스 ━━━${NC}"
    
    if kubectl top nodes &> /dev/null; then
        kubectl top nodes --no-headers 2>/dev/null | awk 'BEGIN {
            printf "%-15s  CPU        MEM\n", "노드"
        }
        {
            printf "%-15s  %3dm/%3dm  %4dMi/%4dMi\n", $1, $2, $3, $4, $5
        }'
    else
        echo "⏳ 메트릭 수집 중..."
    fi
    echo ""
    
    # 4. 파드 상태
    echo -e "${MAGENTA}━━━ 파드 상태 ━━━${NC}"
    
    PODS=$(kubectl get pods -A --no-headers 2>/dev/null)
    RUNNING=$(echo "$PODS" | grep -c "Running")
    PENDING=$(echo "$PODS" | grep -c "Pending")
    FAILED=$(echo "$PODS" | grep -c "Failed")
    ERROR=$(echo "$PODS" | grep -c "CrashLoop\|Error")
    
    echo -n "Running: ${GREEN}$RUNNING${NC} "
    [ "$PENDING" -gt 0 ] && echo -n "| Pending: ${YELLOW}$PENDING${NC} "
    [ "$FAILED" -gt 0 ] && echo -n "| Failed: ${RED}$FAILED${NC} "
    [ "$ERROR" -gt 0 ] && echo -n "| Error: ${RED}$ERROR${NC} "
    echo ""
    
    if [ "$FAILED" -gt 0 ] || [ "$ERROR" -gt 0 ]; then
        echo -e "${RED}문제 파드:${NC}"
        kubectl get pods -A --no-headers 2>/dev/null | grep -E "Failed|CrashLoop|Error" | head -3 | awk '{print "  ✗", $1, $2, $3}'
    fi
    echo ""
    
    # 5. 상위 CPU 파드
    echo -e "${MAGENTA}━━━ TOP CPU 파드 ━━━${NC}"
    if kubectl top pods -A &> /dev/null; then
        kubectl top pods -A --no-headers 2>/dev/null | sort -k3 -nr | head -3 | awk '{print $1, $2, "CPU:", $3}'
    else
        echo "메트릭 수집 중..."
    fi
    echo ""
    
    # 6. 상위 메모리 파드
    echo -e "${MAGENTA}━━━ TOP 메모리 파드 ━━━${NC}"
    if kubectl top pods -A &> /dev/null; then
        kubectl top pods -A --no-headers 2>/dev/null | sort -k4 -nr | head -3 | awk '{print $1, $2, "MEM:", $4}'
    else
        echo "메트릭 수집 중..."
    fi
    echo ""
    
    # 7. 최근 이벤트
    echo -e "${MAGENTA}━━━ 최근 이벤트 ━━━${NC}"
    EVENTS=$(kubectl get events -A --sort-by='.lastTimestamp' 2>/dev/null | grep -E "Warning|Error" | tail -2)
    if [ -z "$EVENTS" ]; then
        echo -e "${GREEN}경고/에러 없음${NC}"
    else
        echo "$EVENTS"
    fi
    echo ""
    
    # 8. 건강도
    echo -e "${MAGENTA}━━━ 클러스터 건강도 ━━━${NC}"
    HEALTH=100
    [ "$NOT_READY_COUNT" -gt 0 ] && HEALTH=$((HEALTH - 30))
    [ "$FAILED" -gt 0 ] && HEALTH=$((HEALTH - 20))
    [ "$ERROR" -gt 0 ] && HEALTH=$((HEALTH - 20))
    
    if [ "$HEALTH" -ge 90 ]; then
        echo -e "상태: ${GREEN}정상${NC} (점수: $HEALTH/100)"
    elif [ "$HEALTH" -ge 70 ]; then
        echo -e "상태: ${YELLOW}주의${NC} (점수: $HEALTH/100)"
    else
        echo -e "상태: ${RED}위험${NC} (점수: $HEALTH/100)"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Ctrl+C${NC}로 종료 | ${UPDATE_INTERVAL}초마다 업데이트"
    echo ""
    
    sleep $UPDATE_INTERVAL
done
