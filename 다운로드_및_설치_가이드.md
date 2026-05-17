# 라즈베리파이에서 K3s 도구 다운로드하기

## 🚀 가장 간단한 방법 (1줄 명령어)

라즈베리파이의 마스터 노드에서 다음을 실행하세요:

### 방법 1: curl 사용
```bash
curl -fsSL https://raw.githubusercontent.com/your-username/your-repo/main/download-k3s-tools.sh | bash
```

### 방법 2: wget 사용
```bash
wget -O - https://raw.githubusercontent.com/your-username/your-repo/main/download-k3s-tools.sh | bash
```

---

## 📋 개별 파일 다운로드

GitHub에 파일을 올렸다면, 각 파일을 개별적으로 다운로드할 수 있습니다:

### 1️⃣ 스크립트 파일 다운로드

```bash
# 디렉토리 생성
mkdir -p ~/k3s-monitor
cd ~/k3s-monitor

# 빠른 상태 확인 스크립트
curl -O https://raw.githubusercontent.com/your-username/your-repo/main/quick-status.sh
chmod +x quick-status.sh

# 실시간 모니터링 스크립트
curl -O https://raw.githubusercontent.com/your-username/your-repo/main/realtime-monitor.sh
chmod +x realtime-monitor.sh

# 상세 진단 스크립트
curl -O https://raw.githubusercontent.com/your-username/your-repo/main/cluster-diagnostics.sh
chmod +x cluster-diagnostics.sh

# 권한 수정 스크립트
curl -O https://raw.githubusercontent.com/your-username/your-repo/main/fix-k3s-permissions.sh
chmod +x fix-k3s-permissions.sh
```

### 2️⃣ 가이드 문서 다운로드

```bash
# 빠른 시작 가이드
curl -O https://raw.githubusercontent.com/your-username/your-repo/main/K3s_빠른_시작_가이드.md

# 모니터링 가이드
curl -O https://raw.githubusercontent.com/your-username/your-repo/main/K3s_클러스터_모니터링_가이드.md

# 권한 해결 가이드
curl -O https://raw.githubusercontent.com/your-username/your-repo/main/K3s_kubectl_권한_해결.md
```

### 3️⃣ 모든 파일 한번에 다운로드

```bash
# 스크립트들
for file in quick-status.sh realtime-monitor.sh cluster-diagnostics.sh fix-k3s-permissions.sh; do
    curl -O https://raw.githubusercontent.com/your-username/your-repo/main/$file
    chmod +x $file
done

# 가이드들 (한글 파일명은 URL 인코딩 필요)
curl -O "https://raw.githubusercontent.com/your-username/your-repo/main/K3s_%EB%B9%A0%EB%A5%B8_%EC%8B%9C%EC%9E%91_%EA%B0%80%EC%9D%B4%EB%93%9C.md"
curl -O "https://raw.githubusercontent.com/your-username/your-repo/main/K3s_%ED%81%B4%EB%9F%AC%EC%8A%A4%ED%84%B0_%EB%AA%A8%EB%8B%88%ED%84%B0%EB%A7%81_%EA%B0%80%EC%9D%B4%EB%93%9C.md"
curl -O "https://raw.githubusercontent.com/your-username/your-repo/main/K3s_kubectl_%EA%B6%8C%ED%95%9C_%ED%95%B4%EA%B2%B0.md"
```

---

## 🔧 GitHub 저장소 설정 방법

### 1단계: GitHub 저장소 생성

1. GitHub에서 새로운 Public 저장소 생성
   - 저장소명: `k3s-monitoring-tools` (예시)
   - Public으로 설정 (누구나 다운로드 가능)

### 2단계: 파일 업로드

```bash
# 로컬 컴퓨터에서 진행

# 1. 저장소 클론
git clone https://github.com/your-username/k3s-monitoring-tools.git
cd k3s-monitoring-tools

# 2. 파일 복사 (이 문서와 함께 제공된 파일들)
cp /path/to/quick-status.sh .
cp /path/to/realtime-monitor.sh .
cp /path/to/cluster-diagnostics.sh .
cp /path/to/fix-k3s-permissions.sh .
cp /path/to/download-k3s-tools.sh .
cp /path/to/*.md .

# 3. Git에 추가
git add .

# 4. 커밋
git commit -m "Add K3s monitoring tools"

# 5. 푸시
git push origin main
```

### 3단계: 라즈베리파이에서 다운로드

```bash
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-monitoring-tools/main/download-k3s-tools.sh | bash
```

---

## 📥 다운로드 스크립트 설정

### 자신의 저장소 URL 설정하기

다운로드 스크립트(`download-k3s-tools.sh`)를 사용하려면, 스크립트 내의 URL을 수정해야 합니다:

```bash
# 1. 스크립트 열기
nano download-k3s-tools.sh

# 2. 다음 줄 찾아서:
GITHUB_RAW_URL="https://raw.githubusercontent.com/your-username/your-repo/main"

# 3. 자신의 정보로 수정:
GITHUB_RAW_URL="https://raw.githubusercontent.com/example-user/k3s-tools/main"

# 4. 저장 (Ctrl+O → Enter → Ctrl+X)
```

---

## 🎯 단계별 실행 가이드

### 라즈베리파이에서 (마스터 노드)

#### 방법 A: 자동 설치 (권장)
```bash
# 1단계: 다운로드 스크립트 받기
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/download-k3s-tools.sh > install.sh
chmod +x install.sh

# 2단계: 실행
./install.sh

# 3단계: 완료 후 권한 수정 (선택사항)
cd ~/k3s-monitor
sudo bash fix-k3s-permissions.sh

# 4단계: 클러스터 상태 확인
./quick-status.sh
```

#### 방법 B: 수동 설치
```bash
# 1단계: 디렉토리 생성
mkdir -p ~/k3s-monitor
cd ~/k3s-monitor

# 2단계: 스크립트 다운로드
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/quick-status.sh
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/realtime-monitor.sh
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/cluster-diagnostics.sh
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/fix-k3s-permissions.sh

# 3단계: 실행 권한 부여
chmod +x *.sh

# 4단계: 권한 문제 해결
sudo bash fix-k3s-permissions.sh

# 5단계: 실행
./quick-status.sh
```

---

## 🔗 직접 링크 (URL 인코딩)

한글 파일명을 URL에서 사용할 때는 인코딩이 필요합니다:

| 파일명 | URL |
|------|-----|
| K3s_빠른_시작_가이드.md | `K3s_%EB%B9%A0%EB%A5%B8_%EC%8B%9C%EC%9E%91_%EA%B0%80%EC%9D%B4%EB%93%9C.md` |
| K3s_클러스터_모니터링_가이드.md | `K3s_%ED%81%B4%EB%9F%AC%EC%8A%A4%ED%84%B0_%EB%AA%A8%EB%8B%88%ED%84%B0%EB%A7%81_%EA%B0%80%EC%9D%B4%EB%93%9C.md` |
| K3s_kubectl_권한_해결.md | `K3s_kubectl_%EA%B6%8C%ED%95%9C_%ED%95%B4%EA%B2%B0.md` |

**더 쉬운 방법**: 파일명을 영어로 변경하면 URL이 간단해집니다.

---

## ⚡ 한번에 설치하는 명령어들

### 전체 설정 (권장)
```bash
# 1. 설치
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/download-k3s-tools.sh | bash

# 2. 권한 수정 (선택)
cd ~/k3s-monitor && sudo bash fix-k3s-permissions.sh

# 3. 상태 확인
./quick-status.sh
```

### 간단히 스크립트만 받기
```bash
mkdir -p ~/k3s-monitor && cd ~/k3s-monitor && \
for f in quick-status.sh realtime-monitor.sh cluster-diagnostics.sh fix-k3s-permissions.sh; do \
  curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/$f && chmod +x $f; \
done && ./quick-status.sh
```

---

## 🐧 여러 라즈베리파이에 설치하기

모든 워커 노드에도 설치하려면:

```bash
# 각 워커 노드에서:
ssh pi@worker1
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/download-k3s-tools.sh | bash

ssh pi@worker2
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/download-k3s-tools.sh | bash
```

또는 마스터 노드에서 일괄 설치:

```bash
# 마스터 노드에서
for node in worker1 worker2 worker3; do
  ssh pi@$node 'curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/download-k3s-tools.sh | bash'
done
```

---

## 🔒 로컬 네트워크에서 사용하기

GitHub 접근이 제한된 경우, 로컬 HTTP 서버에서 제공할 수 있습니다:

### 1단계: 마스터 노드에서 HTTP 서버 시작
```bash
cd ~/k3s-monitor
python3 -m http.server 8000
```

### 2단계: 다른 라즈베리파이에서 다운로드
```bash
mkdir -p ~/k3s-monitor && cd ~/k3s-monitor && \
curl -O http://master-ip:8000/quick-status.sh && \
curl -O http://master-ip:8000/realtime-monitor.sh && \
chmod +x *.sh && \
./quick-status.sh
```

---

## 📝 자신의 환경에 맞게 수정하기

### GitHub 사용자명과 저장소명 변경

모든 명령어에서 다음을 자신의 정보로 변경하세요:

```
your-username  → 자신의 GitHub 사용자명
k3s-tools      → 저장소명
```

예시:
```bash
# 변경 전:
https://raw.githubusercontent.com/your-username/k3s-tools/main/quick-status.sh

# 변경 후:
https://raw.githubusercontent.com/john-doe/raspberry-k3s/main/quick-status.sh
```

---

## 🎯 최종 체크리스트

- [ ] GitHub 저장소 생성
- [ ] 파일 업로드
- [ ] 라즈베리파이에서 다운로드 테스트
- [ ] 스크립트 실행 가능 확인
- [ ] kubectl 권한 문제 해결
- [ ] 모니터링 시작

---

## 📞 도움말

### "Command not found: curl"
```bash
sudo apt update
sudo apt install curl -y
```

### "curl: command not found"는 wget 사용
```bash
wget -O - https://raw.githubusercontent.com/... | bash
```

### "다운로드 속도가 느릴 때"
- GitHub CDN 사용 (기본으로 사용됨)
- 또는 자신의 서버에 파일 호스팅

---

## 🚀 다음 단계

1. GitHub 저장소 생성 및 파일 업로드
2. 라즈베리파이에서 다운로드
3. 스크립트 실행
4. 모니터링 시작!

```bash
# 지금 바로:
./quick-status.sh
```

---

**준비되셨나요? 시작하세요!** 🎉
