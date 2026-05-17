#!/bin/bash

################################################################################
# K3s 모니터링 파일 자동 다운로드 & 설치 스크립트
# 라즈베리파이에서 직접 실행하세요!
#
# 사용법:
# curl -fsSL https://your-domain/download-k3s-tools.sh | bash
# 또는
# wget -O - https://your-domain/download-k3s-tools.sh | bash
################################################################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 설정
DOWNLOAD_DIR="$HOME/k3s-monitor"
GITHUB_RAW_URL="https://raw.githubusercontent.com/your-username/your-repo/main"  # GitHub 사용 시
BACKUP_URL="https://example.com/k3s-tools"  # 백업 URL

# 파일 목록
declare -a FILES=(
    "quick-status.sh"
    "realtime-monitor.sh"
    "cluster-diagnostics.sh"
    "fix-k3s-permissions.sh"
    "K3s_빠른_시작_가이드.md"
    "K3s_클러스터_모니터링_가이드.md"
    "K3s_kubectl_권한_해결.md"
)

################################################################################
# 함수
################################################################################

print_header() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}\n"
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

# 파일 다운로드 함수
download_file() {
    local filename=$1
    local url=$2
    local filepath="$DOWNLOAD_DIR/$filename"
    
    print_info "다운로드 중: $filename"
    
    # curl 시도
    if command -v curl &> /dev/null; then
        if curl -fsSL -o "$filepath" "$url"; then
            print_success "다운로드 완료: $filename"
            return 0
        fi
    fi
    
    # wget 시도
    if command -v wget &> /dev/null; then
        if wget -q -O "$filepath" "$url"; then
            print_success "다운로드 완료: $filename"
            return 0
        fi
    fi
    
    print_error "다운로드 실패: $filename"
    return 1
}

################################################################################
# 메인 실행
################################################################################

clear
print_header "K3s 모니터링 도구 자동 설치"

echo -e "${BLUE}이 스크립트는 다음을 수행합니다:${NC}"
echo "  1. 다운로드 디렉토리 생성: $DOWNLOAD_DIR"
echo "  2. 모든 모니터링 스크립트 다운로드"
echo "  3. 모든 가이드 문서 다운로드"
echo "  4. 실행 권한 설정"
echo ""

# 1단계: 디렉토리 생성
print_header "1️⃣  디렉토리 생성"

if mkdir -p "$DOWNLOAD_DIR"; then
    print_success "디렉토리 생성 완료: $DOWNLOAD_DIR"
else
    print_error "디렉토리 생성 실패"
    exit 1
fi

# 2단계: 파일 다운로드
print_header "2️⃣  파일 다운로드"

DOWNLOADED_COUNT=0
FAILED_COUNT=0

for file in "${FILES[@]}"; do
    echo ""
    
    # 파일 타입별 URL 생성
    if [[ $file == *.sh ]]; then
        # 스크립트 파일
        URL="${GITHUB_RAW_URL}/${file}"
    else
        # 문서 파일
        URL="${GITHUB_RAW_URL}/${file}"
    fi
    
    if download_file "$file" "$URL"; then
        DOWNLOADED_COUNT=$((DOWNLOADED_COUNT + 1))
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        print_warning "백업 URL로 재시도..."
        
        # 백업 URL로 재시도
        BACKUP_FILENAME=$(echo "$file" | sed 's/ /%20/g')
        BACKUP_FILE_URL="${BACKUP_URL}/${BACKUP_FILENAME}"
        
        if download_file "$file" "$BACKUP_FILE_URL"; then
            DOWNLOADED_COUNT=$((DOWNLOADED_COUNT + 1))
        else
            print_error "모든 시도 실패: $file"
        fi
    fi
done

# 3단계: 실행 권한 설정
print_header "3️⃣  실행 권한 설정"

for file in "${FILES[@]}"; do
    if [[ $file == *.sh ]]; then
        filepath="$DOWNLOAD_DIR/$file"
        if [ -f "$filepath" ]; then
            chmod +x "$filepath"
            print_success "권한 설정: $file"
        fi
    fi
done

# 4단계: 권한 문제 해결
print_header "4️⃣  권한 문제 해결 (kubectl)"

print_info "kubectl 권한 자동 수정 중..."
if [ -f "$DOWNLOAD_DIR/fix-k3s-permissions.sh" ]; then
    # 권한 스크립트가 있으면 실행 여부 묻기
    read -p "kubectl 권한을 지금 수정하시겠습니까? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "권한 스정 중..."
        sudo bash "$DOWNLOAD_DIR/fix-k3s-permissions.sh"
    else
        print_info "나중에 수동으로 실행: sudo bash $DOWNLOAD_DIR/fix-k3s-permissions.sh"
    fi
else
    print_warning "권한 스크립트를 찾을 수 없습니다"
fi

# 5단계: 요약 및 완료
print_header "5️⃣  설치 완료!"

echo -e "${GREEN}다운로드 완료:${NC}"
echo "  설치 위치: $DOWNLOAD_DIR"
echo "  다운로드된 파일: $DOWNLOADED_COUNT개"

if [ $FAILED_COUNT -gt 0 ]; then
    print_warning "실패한 파일: $FAILED_COUNT개"
    echo "  → 수동으로 다시 다운로드해주세요"
fi

# 6단계: 파일 목록 표시
print_header "6️⃣  설치된 파일 목록"

echo "📂 디렉토리: $DOWNLOAD_DIR"
echo ""

ls -lh "$DOWNLOAD_DIR" | tail -n +2 | awk '{
    filename=$NF
    size=$(printf "%-8s", $5)
    
    if (filename ~ /\.sh$/) {
        type="🔧 스크립트"
    } else if (filename ~ /\.md$/) {
        type="📖 가이드"
    } else {
        type="📄 파일"
    }
    
    printf "  %s %-30s %s\n", type, filename, size
}'

echo ""

# 7단계: 다음 단계 안내
print_header "🚀 다음 단계"

echo -e "${BLUE}1. 디렉토리로 이동:${NC}"
echo "   cd $DOWNLOAD_DIR"
echo ""

echo -e "${BLUE}2. 빠른 상태 확인:${NC}"
echo "   ./quick-status.sh"
echo ""

echo -e "${BLUE}3. 실시간 모니터링:${NC}"
echo "   ./realtime-monitor.sh"
echo ""

echo -e "${BLUE}4. 상세 진단:${NC}"
echo "   ./cluster-diagnostics.sh"
echo ""

echo -e "${BLUE}5. 문서 보기:${NC}"
echo "   cat K3s_빠른_시작_가이드.md"
echo ""

# 8단계: Alias 설정 제안
print_header "8️⃣  편의 기능 (선택사항)"

read -p "~/.bashrc에 별칭(alias)를 추가하시겠습니까? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "별칭 설정 중..."
    
    cat >> ~/.bashrc << 'EOF'

# K3s 모니터링 도구 별칭 (자동 추가)
export K3S_MONITOR_DIR="$HOME/k3s-monitor"
alias k3s-quick="$K3S_MONITOR_DIR/quick-status.sh"
alias k3s-monitor="$K3S_MONITOR_DIR/realtime-monitor.sh"
alias k3s-diag="$K3S_MONITOR_DIR/cluster-diagnostics.sh"
alias k3s-fix="sudo bash $K3S_MONITOR_DIR/fix-k3s-permissions.sh"
EOF

    print_success "별칭 설정 완료"
    print_info "적용하려면: source ~/.bashrc"
    print_info "또는 터미널 재시작"
    
    echo ""
    echo "설정된 별칭:"
    echo "  k3s-quick     → 빠른 상태 확인"
    echo "  k3s-monitor   → 실시간 모니터링"
    echo "  k3s-diag      → 상세 진단"
    echo "  k3s-fix       → kubectl 권한 수정"
else
    print_info "별칭 설정을 건너뛰었습니다"
fi

# 9단계: 최종 체크
print_header "✅ 설치 완료!"

print_success "모든 파일이 설치되었습니다"
echo ""
echo -e "${GREEN}지금 바로 시작하세요:${NC}"
echo ""
echo "  cd $DOWNLOAD_DIR"
echo "  ./quick-status.sh"
echo ""

print_info "더 자세한 정보는 가이드를 참고하세요:"
echo "  less K3s_빠른_시작_가이드.md"
echo ""

################################################################################
# 설정 파일 생성
################################################################################

print_header "🔧 설정 파일 생성"

cat > "$DOWNLOAD_DIR/config.sh" << 'EOF'
#!/bin/bash
# K3s 모니터링 도구 설정 파일

# 마스터 노드 IP (자동 감지 또는 수동 설정)
MASTER_IP="${MASTER_IP:-localhost}"
MASTER_HOSTNAME="${MASTER_HOSTNAME:-master}"

# 모니터링 설정
UPDATE_INTERVAL=10  # 초 단위
HISTORY_SIZE=100    # 저장할 이벤트 수

# 색상 설정 (비활성화 하려면 true -> false)
USE_COLORS=true
USE_EMOJI=true

# 로그 파일
LOG_DIR="$HOME/.k3s-monitor-logs"
DIAG_LOG_FILE="$LOG_DIR/cluster-diagnostics-$(date +%Y%m%d_%H%M%S).log"

# 디렉토리 자동 생성
mkdir -p "$LOG_DIR"
EOF

chmod +x "$DOWNLOAD_DIR/config.sh"
print_success "설정 파일 생성: config.sh"

echo ""
print_header "완료!"

echo -e "${GREEN}✅ 설치가 완료되었습니다!${NC}"
echo ""
echo -e "${CYAN}다음 명령어를 실행하세요:${NC}"
echo ""
echo "  ${BLUE}cd $DOWNLOAD_DIR${NC}"
echo "  ${BLUE}./quick-status.sh${NC}"
echo ""
