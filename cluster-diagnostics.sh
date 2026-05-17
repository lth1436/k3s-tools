#!/bin/bash

################################################################################
# K3s 클러스터 상세 진단 & 트러블슈팅 스크립트
# 사용법: ./cluster-diagnostics.sh
################################################################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 로그 파일
LOG_FILE="cluster-diagnostics-$(date +%Y%m%d_%H%M%S).log"

# 함수: 메시지 출력 (화면 + 로그)
log_output() {
    echo "$1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${CYAN}════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}════════════════════════════════════════════════${NC}\n" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}" | tee -a "$LOG_FILE"
}

################################################################################
# 메인 진단
################################################################################

clear
print_header "K3s 클러스터 상세 진단 시작"
log_output "진단 시작 시간: $(date)"
log_output "로그 파일: $LOG_FILE\n"

# 1. 시스템 정보
print_header "1️⃣  시스템 정보"

log_output "호스트명: $(hostname)"
log_output "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
log_output "커널: $(uname -r)"
log_output "CPU 코어: $(nproc)"
log_output "메모리: $(free -h | grep Mem | awk '{print $2}')"
log_output "디스크: $(df -h / | tail -1 | awk '{print $2}')"
log_output ""

# 2. K3s 설치 확인
print_header "2️⃣  K3s 설치 상태"

if ! command -v k3s &> /dev/null; then
    print_error "K3s가 설치되어 있지 않습니다"
    exit 1
fi

print_success "K3s 설치 확인됨"

K3S_VERSION=$(k3s --version 2>/dev/null | head -1)
log_output "K3s 버전: $K3S_VERSION"

# K3s 서비스 상태 확인
if sudo systemctl is-active --quiet k3s 2>/dev/null || sudo systemctl is-active --quiet k3s-agent 2>/dev/null; then
    print_success "K3s 서비스 실행 중"
else
    print_warning "K3s 서비스가 실행 중이 아닐 수 있습니다"
fi

log_output ""

# 3. kubectl 확인
print_header "3️⃣  kubectl 연결 상태"

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl이 설치되어 있지 않습니다"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    print_error "클러스터에 연결할 수 없습니다"
    log_output "에러 메시지:"
    kubectl cluster-info 2>&1 | tee -a "$LOG_FILE"
    exit 1
fi

print_success "클러스터에 연결됨"
kubectl cluster-info 2>&1 | tee -a "$LOG_FILE"
log_output ""

# 4. 노드 상세 진단
print_header "4️⃣  노드 상세 진단"

NODES=$(kubectl get nodes --no-headers 2>/dev/null)
NODE_COUNT=$(echo "$NODES" | wc -l)

log_output "총 노드 수: $NODE_COUNT\n"

echo "$NODES" | while read -r line; do
    NODE_NAME=$(echo "$line" | awk '{print $1}')
    STATUS=$(echo "$line" | awk '{print $2}')
    
    log_output "━━━ 노드: $NODE_NAME ━━━"
    
    # 기본 정보
    if [ "$STATUS" = "Ready" ]; then
        print_success "상태: Ready"
    else
        print_error "상태: $STATUS"
    fi
    
    # 상세 정보
    NODE_INFO=$(kubectl describe node "$NODE_NAME" 2>/dev/null)
    
    # IP 주소
    INTERNAL_IP=$(echo "$NODE_INFO" | grep "InternalIP" | awk '{print $2}')
    EXTERNAL_IP=$(echo "$NODE_INFO" | grep "ExternalIP" | awk '{print $2}')
    log_output "내부 IP: $INTERNAL_IP"
    if [ ! -z "$EXTERNAL_IP" ]; then
        log_output "외부 IP: $EXTERNAL_IP"
    fi
    
    # 용량
    CAPACITY=$(echo "$NODE_INFO" | grep -A 10 "Capacity:" | head -3)
    log_output "용량 정보:"
    echo "$CAPACITY" | sed 's/^/  /' | tee -a "$LOG_FILE"
    
    # 할당 가능
    ALLOCATABLE=$(echo "$NODE_INFO" | grep -A 10 "Allocatable:" | head -3)
    log_output "할당 가능:"
    echo "$ALLOCATABLE" | sed 's/^/  /' | tee -a "$LOG_FILE"
    
    # Conditions
    CONDITIONS=$(echo "$NODE_INFO" | grep -A 20 "Conditions:" | head -10)
    log_output "상태 조건:"
    echo "$CONDITIONS" | sed 's/^/  /' | tee -a "$LOG_FILE"
    
    # 실행 중인 파드
    POD_COUNT=$(kubectl get pods --all-namespaces --field-selector spec.nodeName="$NODE_NAME" --no-headers 2>/dev/null | wc -l)
    log_output "실행 중인 파드: $POD_COUNT개"
    
    log_output ""
done

# 5. 파드 상태 진단
print_header "5️⃣  파드 상태 진단"

PODS=$(kubectl get pods -A --no-headers 2>/dev/null)

RUNNING=$(echo "$PODS" | grep -c "Running" || echo 0)
PENDING=$(echo "$PODS" | grep -c "Pending" || echo 0)
FAILED=$(echo "$PODS" | grep -c "Failed" || echo 0)
ERRORED=$(echo "$PODS" | grep -c "CrashLoop\|Error" || echo 0)

log_output "전체 파드: $(echo "$PODS" | wc -l)개"
print_success "Running: $RUNNING"

if [ "$PENDING" -gt 0 ]; then
    print_warning "Pending: $PENDING"
fi

if [ "$FAILED" -gt 0 ] || [ "$ERRORED" -gt 0 ]; then
    print_error "Failed/Error: $((FAILED + ERRORED))"
    
    log_output "\n문제가 있는 파드 목록:"
    kubectl get pods -A --no-headers 2>/dev/null | grep -E "Failed|CrashLoop|Error" | \
        while read line; do
            NS=$(echo "$line" | awk '{print $1}')
            POD=$(echo "$line" | awk '{print $2}')
            STATUS=$(echo "$line" | awk '{print $3}')
            RESTARTS=$(echo "$line" | awk '{print $4}')
            
            log_output "\n  파드: $NS/$POD"
            log_output "  상태: $STATUS | 재시작: $RESTARTS"
            
            # 파드 로그
            log_output "  최근 로그:"
            kubectl logs "$POD" -n "$NS" --tail=5 2>/dev/null | sed 's/^/    /' | tee -a "$LOG_FILE" || \
                log_output "    (로그 조회 불가)"
        done
fi

log_output ""

# 6. 리소스 사용량 분석
print_header "6️⃣  리소스 사용량 분석"

if kubectl top nodes &> /dev/null; then
    log_output "━━━ 노드별 리소스 사용량 ━━━"
    kubectl top nodes 2>/dev/null | tee -a "$LOG_FILE"
    
    log_output "\n━━━ TOP 10 CPU 사용 파드 ━━━"
    kubectl top pods -A --no-headers 2>/dev/null | sort -k3 -nr | head -10 | \
        awk '{printf "%-25s %-40s CPU: %4s\n", $1, $2, $3}' | tee -a "$LOG_FILE"
    
    log_output "\n━━━ TOP 10 메모리 사용 파드 ━━━"
    kubectl top pods -A --no-headers 2>/dev/null | sort -k4 -nr | head -10 | \
        awk '{printf "%-25s %-40s MEM: %5s\n", $1, $2, $4}' | tee -a "$LOG_FILE"
else
    print_warning "메트릭 서버가 준비되지 않았습니다 (1분 이상 대기 필요)"
fi

log_output ""

# 7. 네트워크 진단
print_header "7️⃣  네트워크 진단"

# DNS 확인
log_output "━━━ DNS 서비스 ━━━"
kubectl get svc -n kube-system -o wide 2>/dev/null | grep dns | tee -a "$LOG_FILE"

# CNI 확인
log_output "\n━━━ 네트워크 플러그인 ━━━"
CNI_INFO=$(kubectl get daemonset -n kube-system -o name 2>/dev/null | grep -E "canal|flannel|weave|cilium")
if [ ! -z "$CNI_INFO" ]; then
    log_output "$CNI_INFO"
else
    log_output "CNI 플러그인을 찾을 수 없습니다"
fi

# 네트워크 정책 확인
log_output "\n━━━ 네트워크 정책 ━━━"
NP_COUNT=$(kubectl get networkpolicies -A --no-headers 2>/dev/null | wc -l)
log_output "네트워크 정책: $NP_COUNT개"

log_output ""

# 8. 스토리지 진단
print_header "8️⃣  스토리지 진단"

log_output "━━━ PersistentVolume ━━━"
PV_COUNT=$(kubectl get pv --no-headers 2>/dev/null | wc -l)
log_output "전체: $PV_COUNT개"
kubectl get pv 2>/dev/null | tee -a "$LOG_FILE"

log_output "\n━━━ PersistentVolumeClaim ━━━"
PVC_COUNT=$(kubectl get pvc -A --no-headers 2>/dev/null | wc -l)
log_output "전체: $PVC_COUNT개"
kubectl get pvc -A 2>/dev/null | head -20 | tee -a "$LOG_FILE"

log_output "\n━━━ StorageClass ━━━"
SC_COUNT=$(kubectl get sc --no-headers 2>/dev/null | wc -l)
log_output "전체: $SC_COUNT개"
kubectl get sc 2>/dev/null | tee -a "$LOG_FILE"

log_output ""

# 9. 이벤트 분석
print_header "9️⃣  최근 이벤트 분석"

log_output "━━━ 모든 Warning/Error 이벤트 ━━━"
EVENTS=$(kubectl get events -A --sort-by='.lastTimestamp' 2>/dev/null | grep -E "Warning|Error")

if [ -z "$EVENTS" ]; then
    print_success "최근 경고/에러 없음"
else
    echo "$EVENTS" | tail -20 | tee -a "$LOG_FILE"
fi

log_output ""

# 10. RBAC 진단
print_header "🔟 RBAC 및 권한"

log_output "━━━ ServiceAccount ━━━"
SA_COUNT=$(kubectl get sa -A --no-headers 2>/dev/null | wc -l)
log_output "전체: $SA_COUNT개"

log_output "\n━━━ ClusterRole ━━━"
CR_COUNT=$(kubectl get clusterroles --no-headers 2>/dev/null | wc -l)
log_output "전체: $CR_COUNT개"

log_output "\n━━━ ClusterRoleBinding ━━━"
CRB_COUNT=$(kubectl get clusterrolebindings --no-headers 2>/dev/null | wc -l)
log_output "전체: $CRB_COUNT개"

log_output ""

# 11. 시스템 로그
print_header "1️⃣1️⃣  시스템 로그"

if [ -f /var/lib/rancher/k3s/agent/containerd/containerd.log ]; then
    log_output "━━━ K3s Agent 로그 (최근 50줄) ━━━"
    tail -50 /var/lib/rancher/k3s/agent/containerd/containerd.log 2>/dev/null | tee -a "$LOG_FILE" || \
        print_warning "로그 파일 접근 불가 (권한 필요)"
fi

if command -v journalctl &> /dev/null; then
    log_output "\n━━━ K3s 서비스 로그 (최근 30줄) ━━━"
    journalctl -u k3s -n 30 --no-pager 2>/dev/null | tee -a "$LOG_FILE" || \
    journalctl -u k3s-agent -n 30 --no-pager 2>/dev/null | tee -a "$LOG_FILE"
fi

log_output ""

# 12. 최종 권장사항
print_header "1️⃣2️⃣  권장사항"

# 분석 및 권장
ISSUES=0

if [ "$NOT_READY_COUNT" -gt 0 ] 2>/dev/null; then
    print_warning "NotReady 노드가 있습니다"
    log_output "해결책:"
    log_output "  1. SSH로 해당 노드에 접속"
    log_output "  2. sudo systemctl restart k3s-agent 실행"
    log_output "  3. sudo journalctl -u k3s-agent -n 50 에러 확인"
    ISSUES=$((ISSUES + 1))
fi

if [ "$FAILED" -gt 0 ] 2>/dev/null; then
    print_warning "실패한 파드가 있습니다"
    log_output "해결책:"
    log_output "  1. kubectl delete pod <pod-name> -n <ns>로 파드 재생성"
    log_output "  2. kubectl logs <pod-name> -n <ns>로 로그 확인"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    print_success "심각한 문제가 없습니다"
fi

log_output ""

# 최종 정보
print_header "✅ 진단 완료"
log_output "진단 종료 시간: $(date)"
log_output "로그 파일: $LOG_FILE"
log_output ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}상세 로그는 다음 파일에 저장되었습니다:${NC}"
echo -e "${BLUE}$LOG_FILE${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
