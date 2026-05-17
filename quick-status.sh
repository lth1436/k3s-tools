#!/bin/bash

################################################################################
# K3s 클러스터 빠른 상태 확인 스크립트
# 사용법: ./quick-status.sh
################################################################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수: 메시지 출력
print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

################################################################################
# 메인 실행
################################################################################

clear
print_header "K3s 클러스터 상태 확인"

# 1단계: kubectl 명령어 사용 가능 확인
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl이 설치되어 있지 않습니다!"
    echo "설치: curl -sfL https://get.k3s.io | sh -"
    exit 1
fi

# 2단계: 클러스터 연결 확인
print_header "1️⃣  클러스터 연결 확인"

if kubectl cluster-info &> /dev/null; then
    print_success "클러스터에 연결됨"
    CLUSTER_VERSION=$(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')
    print_info "K3s 버전: $CLUSTER_VERSION"
else
    print_error "클러스터에 연결할 수 없습니다!"
    echo "확인: KUBECONFIG 설정, 마스터 노드 상태"
    exit 1
fi

# 3단계: 노드 상태
print_header "2️⃣  노드 상태"

NODES=$(kubectl get nodes --no-headers)
READY_COUNT=$(echo "$NODES" | grep -c "Ready")
NOT_READY_COUNT=$(echo "$NODES" | grep -c "NotReady")
TOTAL_COUNT=$(echo "$NODES" | wc -l)

echo "$NODES" | awk '{
    status = $2
    if (status ~ /Ready/) {
        color = "\033[0;32m"
        symbol = "✓"
    } else {
        color = "\033[0;31m"
        symbol = "✗"
    }
    printf "%s%-15s%s %-10s (Age: %s, Version: %s)\n", color, $1, "\033[0m", status, $5, $6
}'

echo ""
print_info "전체: $TOTAL_COUNT / Ready: $READY_COUNT / NotReady: $NOT_READY_COUNT"

if [ "$NOT_READY_COUNT" -gt 0 ]; then
    print_warning "일부 노드가 Ready 상태가 아닙니다!"
else
    print_success "모든 노드가 Ready 상태입니다!"
fi

# 4단계: 파드 상태
print_header "3️⃣  파드 상태 (모든 네임스페이스)"

PODS=$(kubectl get pods -A --no-headers 2>/dev/null)
RUNNING=$(echo "$PODS" | grep -c "Running" || echo 0)
PENDING=$(echo "$PODS" | grep -c "Pending" || echo 0)
FAILED=$(echo "$PODS" | grep -c "Failed" || echo 0)
ERRORED=$(echo "$PODS" | grep -c "Error" || echo 0)
TOTAL_PODS=$(echo "$PODS" | wc -l)

print_info "전체 파드: $TOTAL_PODS"
print_success "Running: $RUNNING"

if [ "$PENDING" -gt 0 ]; then
    print_warning "Pending: $PENDING (시작 대기 중)"
fi

if [ "$FAILED" -gt 0 ] || [ "$ERRORED" -gt 0 ]; then
    print_error "Failed/Error: $(($FAILED + $ERRORED))"
    echo ""
    print_warning "문제가 있는 파드:"
    kubectl get pods -A --no-headers 2>/dev/null | grep -E "Failed|Error|CrashLoop" | while read line; do
        echo "  $line"
    done
fi

# 5단계: 리소스 사용량
print_header "4️⃣  리소스 사용량"

print_info "노드별 CPU 및 메모리 사용률:"
echo ""
kubectl top nodes --no-headers 2>/dev/null | awk '{
    cpu_pct = int($2 / $3 * 100)
    mem_pct = int($4 / $5 * 100)
    
    # 색상 결정
    if (cpu_pct > 80) cpu_color = "\033[0;31m"
    else if (cpu_pct > 60) cpu_color = "\033[1;33m"
    else cpu_color = "\033[0;32m"
    
    if (mem_pct > 80) mem_color = "\033[0;31m"
    else if (mem_pct > 60) mem_color = "\033[1;33m"
    else mem_color = "\033[0;32m"
    
    printf "%-15s CPU: %s%3d%%\033[0m (%3dm/%4dm)  MEM: %s%3d%%\033[0m (%4dMi/%5dMi)\n", \
        $1, cpu_color, cpu_pct, $2, $3, mem_color, mem_pct, $4, $5
}' || print_error "메트릭 서버가 응답하지 않습니다 (1분 대기 후 재시도)"

echo ""
print_info "TOP 5 CPU 사용 파드:"
kubectl top pods -A --no-headers 2>/dev/null | sort -k3 -nr | head -5 | while read ns name cpu mem; do
    printf "  %-25s %-40s CPU: %4s\n" "$ns" "$name" "$cpu"
done || print_warning "메트릭 데이터 없음"

echo ""
print_info "TOP 5 메모리 사용 파드:"
kubectl top pods -A --no-headers 2>/dev/null | sort -k4 -nr | head -5 | while read ns name cpu mem; do
    printf "  %-25s %-40s MEM: %5s\n" "$ns" "$name" "$mem"
done || print_warning "메트릭 데이터 없음"

# 6단계: 시스템 파드 상태
print_header "5️⃣  시스템 파드 상태 (kube-system)"

SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null)
SYSTEM_RUNNING=$(echo "$SYSTEM_PODS" | grep -c "Running" || echo 0)
SYSTEM_FAILED=$(echo "$SYSTEM_PODS" | grep -c "Failed\|Error\|CrashLoop" || echo 0)

print_info "실행 중: $SYSTEM_RUNNING / 문제 있음: $SYSTEM_FAILED"

if [ "$SYSTEM_FAILED" -gt 0 ]; then
    print_warning "문제가 있는 시스템 파드:"
    kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -E "Failed|Error|CrashLoop" | while read line; do
        echo "  $line"
    done
fi

# 7단계: 최근 이벤트
print_header "6️⃣  최근 이벤트 (Warning/Error)"

EVENTS=$(kubectl get events -A --sort-by='.lastTimestamp' 2>/dev/null | grep -E "Warning|Error" | tail -5)

if [ -z "$EVENTS" ]; then
    print_success "최근 경고 또는 에러 없음"
else
    print_warning "최근 경고/에러:"
    echo "$EVENTS" | while read line; do
        echo "  $line"
    done
fi

# 8단계: 스토리지 상태
print_header "7️⃣  스토리지 상태"

PV_COUNT=$(kubectl get pv --no-headers 2>/dev/null | wc -l)
PVC_COUNT=$(kubectl get pvc -A --no-headers 2>/dev/null | wc -l)

if [ "$PV_COUNT" -eq 0 ] && [ "$PVC_COUNT" -eq 0 ]; then
    print_info "PersistentVolume/PVC 없음"
else
    print_info "PersistentVolume: $PV_COUNT개"
    print_info "PersistentVolumeClaim: $PVC_COUNT개"
    
    # Bound가 아닌 PVC 확인
    UNBOUND=$(kubectl get pvc -A --no-headers 2>/dev/null | grep -v Bound | wc -l || echo 0)
    if [ "$UNBOUND" -gt 0 ]; then
        print_warning "Bound되지 않은 PVC: $UNBOUND개"
    fi
fi

# 9단계: 최종 요약
print_header "📊 최종 요약"

HEALTH_SCORE=100

# 노드 상태 확인
if [ "$NOT_READY_COUNT" -gt 0 ]; then
    HEALTH_SCORE=$((HEALTH_SCORE - 30))
fi

# 파드 상태 확인
if [ "$FAILED" -gt 0 ] || [ "$ERRORED" -gt 0 ]; then
    HEALTH_SCORE=$((HEALTH_SCORE - 20))
fi

# 리소스 확인
CPU_HIGH=$(kubectl top nodes --no-headers 2>/dev/null | grep -c "[89][0-9]%\|100%" || echo 0)
MEM_HIGH=$(kubectl top nodes --no-headers 2>/dev/null | awk '{if($4/$5*100>80) print}' | wc -l)

if [ "$CPU_HIGH" -gt 0 ] || [ "$MEM_HIGH" -gt 0 ]; then
    HEALTH_SCORE=$((HEALTH_SCORE - 10))
fi

# 상태 표시
if [ "$HEALTH_SCORE" -ge 90 ]; then
    print_success "클러스터 상태: 정상 ($HEALTH_SCORE/100)"
elif [ "$HEALTH_SCORE" -ge 70 ]; then
    print_warning "클러스터 상태: 주의 필요 ($HEALTH_SCORE/100)"
else
    print_error "클러스터 상태: 문제 있음 ($HEALTH_SCORE/100)"
fi

# 10단계: 유용한 다음 명령어
print_header "💡 유용한 명령어"

echo "더 자세한 정보:"
echo "  ${BLUE}kubectl get nodes -o wide${NC}           # 노드 상세 정보"
echo "  ${BLUE}kubectl get pods -A${NC}                 # 모든 파드"
echo "  ${BLUE}kubectl describe node <name>${NC}         # 특정 노드 상세 정보"
echo "  ${BLUE}kubectl logs -f <pod> -n <ns>${NC}       # 파드 실시간 로그"
echo "  ${BLUE}kubectl get events -A${NC}               # 전체 이벤트"
echo ""
echo "모니터링 (실시간):"
echo "  ${BLUE}watch kubectl get nodes${NC}"
echo "  ${BLUE}watch kubectl top nodes${NC}"
echo ""
echo "문제 해결:"
echo "  ${BLUE}kubectl describe pod <name> -n <ns>${NC} # 파드 문제 확인"
echo "  ${BLUE}kubectl delete pod <name> -n <ns>${NC}   # 파드 재시작"
echo ""

print_header "✅ 상태 확인 완료"
echo "시간: $(date)"
echo ""
