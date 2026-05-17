#!/bin/bash

################################################################################
# K3s kubectl 권한 자동 수정 스크립트
# 사용법: sudo bash ./fix-k3s-permissions.sh
################################################################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
print_header "K3s kubectl 권한 자동 수정"

# Root 권한 확인
if [ "$EUID" -ne 0 ]; then
    print_error "이 스크립트는 sudo 권한이 필요합니다!"
    echo "다시 실행: sudo bash $0"
    exit 1
fi

# 1단계: K3s 설치 확인
print_header "1️⃣  K3s 설치 상태 확인"

if ! command -v k3s &> /dev/null; then
    print_error "K3s가 설치되어 있지 않습니다"
    exit 1
fi

print_success "K3s 설치 확인됨"
print_info "버전: $(k3s --version 2>/dev/null | head -1)"

# 2단계: kubeconfig 파일 찾기
print_header "2️⃣  kubeconfig 파일 확인"

KUBECONFIG_FILE="/etc/rancher/k3s/k3s.yaml"

if [ ! -f "$KUBECONFIG_FILE" ]; then
    print_error "kubeconfig 파일을 찾을 수 없습니다: $KUBECONFIG_FILE"
    exit 1
fi

print_success "파일 위치: $KUBECONFIG_FILE"

# 현재 권한 확인
CURRENT_PERMS=$(stat -c '%a' "$KUBECONFIG_FILE")
CURRENT_OWNER=$(stat -c '%U:%G' "$KUBECONFIG_FILE")

print_info "현재 권한: $CURRENT_PERMS"
print_info "현재 소유자: $CURRENT_OWNER"

# 3단계: 현재 사용자 확인
print_header "3️⃣  사용자 확인"

# pi 사용자 확인
if id "pi" &>/dev/null; then
    TARGET_USER="pi"
    print_success "사용자 'pi' 존재"
else
    # 다른 사용자 찾기
    TARGET_USER=$(ls /home 2>/dev/null | head -1)
    if [ -z "$TARGET_USER" ]; then
        print_warning "pi 사용자를 찾을 수 없습니다"
        read -p "대상 사용자명 입력: " TARGET_USER
    else
        print_warning "pi 사용자를 찾을 수 없어서 '$TARGET_USER' 사용합니다"
    fi
fi

print_info "대상 사용자: $TARGET_USER"

# 4단계: 권한 수정
print_header "4️⃣  권한 수정"

print_info "다음과 같이 변경합니다:"
echo "  소유자: $CURRENT_OWNER → $TARGET_USER:$TARGET_USER"
echo "  권한: $CURRENT_PERMS → 644 (읽기 가능)"

# 소유자 변경
print_info "소유자 변경 중..."
chown "$TARGET_USER:$TARGET_USER" "$KUBECONFIG_FILE"

if [ $? -eq 0 ]; then
    print_success "소유자 변경 완료"
else
    print_error "소유자 변경 실패"
    exit 1
fi

# 권한 변경
print_info "권한 변경 중..."
chmod 644 "$KUBECONFIG_FILE"

if [ $? -eq 0 ]; then
    print_success "권한 변경 완료"
else
    print_error "권한 변경 실패"
    exit 1
fi

# 5단계: 전체 디렉토리 권한 확인
print_header "5️⃣  K3s 디렉토리 권한 확인"

if [ -d "/etc/rancher/k3s" ]; then
    print_info "/etc/rancher/k3s 권한 정리"
    
    # kubeconfig 파일만 수정 (다른 파일은 root 소유 유지)
    print_success "kubeconfig 파일: $TARGET_USER 소유로 설정"
fi

# 6단계: 변경 사항 확인
print_header "6️⃣  변경 사항 확인"

NEW_PERMS=$(stat -c '%a' "$KUBECONFIG_FILE")
NEW_OWNER=$(stat -c '%U:%G' "$KUBECONFIG_FILE")

print_info "새로운 권한: $NEW_PERMS"
print_info "새로운 소유자: $NEW_OWNER"

if [ "$NEW_OWNER" = "$TARGET_USER:$TARGET_USER" ] && [ "$NEW_PERMS" = "644" ]; then
    print_success "권한 수정 완료!"
else
    print_error "권한 수정이 제대로 되지 않았습니다"
    exit 1
fi

# 7단계: kubectl 테스트
print_header "7️⃣  kubectl 연결 테스트"

# su로 대상 사용자로 전환하여 테스트
TEST_CMD="kubectl cluster-info 2>&1"

print_info "테스트 명령어: kubectl cluster-info"

if su - "$TARGET_USER" -c "$TEST_CMD" | grep -q "running"; then
    print_success "kubectl 연결 성공!"
else
    # K3s 서비스 상태 확인
    print_warning "kubectl 테스트가 실패했습니다. K3s 서비스 상태 확인..."
    
    if systemctl is-active --quiet k3s; then
        print_success "K3s 마스터 서비스: 실행 중"
    elif systemctl is-active --quiet k3s-agent; then
        print_success "K3s 에이전트 서비스: 실행 중"
    else
        print_error "K3s 서비스가 실행 중이 아닙니다"
        print_info "다시 시작 중..."
        
        if systemctl exists k3s; then
            systemctl start k3s
            sleep 3
            print_info "K3s 마스터 서비스 시작됨"
        elif systemctl exists k3s-agent; then
            systemctl start k3s-agent
            sleep 3
            print_info "K3s 에이전트 서비스 시작됨"
        fi
    fi
    
    # 재테스트
    print_info "재테스트 중..."
    if su - "$TARGET_USER" -c "kubectl cluster-info 2>&1" | grep -q "running"; then
        print_success "kubectl 연결 성공!"
    else
        print_warning "kubectl 테스트 여전히 실패 (K3s 초기화 중일 수 있음, 1분 후 재시도)"
    fi
fi

# 8단계: 완료 정보
print_header "✅ 권한 수정 완료!"

print_success "다음 명령어를 사용할 수 있습니다:"
echo ""
echo -e "  ${BLUE}kubectl get nodes${NC}"
echo -e "  ${BLUE}kubectl get pods -A${NC}"
echo -e "  ${BLUE}./quick-status.sh${NC}"
echo -e "  ${BLUE}./realtime-monitor.sh${NC}"
echo ""

print_info "변경 사항:"
echo "  • kubeconfig 파일: root:root → $TARGET_USER:$TARGET_USER"
echo "  • 파일 권한: $CURRENT_PERMS → $NEW_PERMS"
echo ""

# 9단계: 다음 단계 안내
print_header "🚀 다음 단계"

print_info "다음 중 하나를 실행하세요:"
echo ""
echo "1. 클러스터 상태 빠른 확인:"
echo -e "   ${BLUE}./quick-status.sh${NC}"
echo ""
echo "2. 실시간 모니터링:"
echo -e "   ${BLUE}./realtime-monitor.sh${NC}"
echo ""
echo "3. 상세 진단:"
echo -e "   ${BLUE}./cluster-diagnostics.sh${NC}"
echo ""

# 10단계: 수동 테스트 제안
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
print_info "수동 테스트 (선택사항):"
echo ""
echo "  su - $TARGET_USER"
echo -e "  ${BLUE}kubectl get nodes${NC}"
echo ""

print_header "완료!"
echo -e "${GREEN}스크립트 종료${NC}\n"
