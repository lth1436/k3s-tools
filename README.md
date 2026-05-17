# K3s 모니터링 도구 - 다운로드 및 설치 가이드

## ⚡ 가장 간단한 방법 (1줄)

라즈베리파이에서 다음을 실행하기만 하면 됩니다:

```bash
# Option 1: 자동 다운로드 스크립트 사용 (권장)
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/install.sh | bash

# Option 2: 수동으로 스크립트만 받기
mkdir -p ~/k3s-monitor && cd ~/k3s-monitor && \
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/quick-status.sh && \
chmod +x quick-status.sh && \
./quick-status.sh
```

---

## 📥 개별 파일 다운로드 링크

### 🔧 스크립트 파일들

각 링크를 복사해서 라즈베리파이에서 실행하세요:

#### 1️⃣ 자동 설치 스크립트 (가장 권장!)
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/install.sh
chmod +x install.sh
./install.sh
```

#### 2️⃣ 빠른 상태 확인
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/quick-status.sh
chmod +x quick-status.sh
./quick-status.sh
```

#### 3️⃣ 실시간 모니터링
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/realtime-monitor.sh
chmod +x realtime-monitor.sh
./realtime-monitor.sh
```

#### 4️⃣ 상세 진단
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/cluster-diagnostics.sh
chmod +x cluster-diagnostics.sh
./cluster-diagnostics.sh
```

#### 5️⃣ kubectl 권한 수정
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/fix-k3s-permissions.sh
chmod +x fix-k3s-permissions.sh
sudo bash fix-k3s-permissions.sh
```

---

### 📖 가이드 문서들

#### 1️⃣ 빠른 시작 가이드
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/quick-start.md
less quick-start.md
```

#### 2️⃣ 모니터링 완전 가이드
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/monitoring-guide.md
less monitoring-guide.md
```

#### 3️⃣ kubectl 권한 문제 해결
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/permission-fix.md
less permission-fix.md
```

#### 4️⃣ 다운로드 및 설치 가이드
```bash
curl -O https://raw.githubusercontent.com/your-username/k3s-tools/main/download-guide.md
less download-guide.md
```

---

## 🚀 설정 단계별 가이드

### Step 1: GitHub 저장소 준비

1. GitHub에서 새로운 Public 저장소 생성
2. 저장소명: `k3s-tools` (또는 원하는 이름)
3. 다음 파일들을 업로드:

| 파일명 (로컬) | 저장소에 올릴 파일명 |
|-------------|------------------|
| download-k3s-tools.sh | install.sh |
| quick-status.sh | quick-status.sh |
| realtime-monitor.sh | realtime-monitor.sh |
| cluster-diagnostics.sh | cluster-diagnostics.sh |
| fix-k3s-permissions.sh | fix-k3s-permissions.sh |
| K3s_빠른_시작_가이드.md | quick-start.md |
| K3s_클러스터_모니터링_가이드.md | monitoring-guide.md |
| K3s_kubectl_권한_해결.md | permission-fix.md |
| 다운로드_및_설치_가이드.md | download-guide.md |

### Step 2: 라즈베리파이에서 설치

```bash
# 마스터 노드에서 실행
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/install.sh | bash
```

### Step 3: 권한 설정 (선택)

```bash
cd ~/k3s-monitor
sudo bash fix-k3s-permissions.sh
```

### Step 4: 모니터링 시작!

```bash
./quick-status.sh
```

---

## 📋 GitHub 저장소 예시 구조

```
k3s-tools/
├── README.md                   # 프로젝트 설명
├── install.sh                  # 자동 설치 스크립트
├── quick-status.sh             # 빠른 상태 확인
├── realtime-monitor.sh         # 실시간 모니터링
├── cluster-diagnostics.sh      # 상세 진단
├── fix-k3s-permissions.sh      # 권한 수정
├── quick-start.md              # 빠른 시작
├── monitoring-guide.md         # 모니터링 가이드
├── permission-fix.md           # 권한 해결
└── download-guide.md           # 다운로드 가이드
```

---

## 🔗 실제 GitHub URL 예시

귀하의 GitHub 정보를 대입해서 사용하세요:

```
https://raw.githubusercontent.com/{USERNAME}/{REPO}/main/{FILENAME}

예시:
https://raw.githubusercontent.com/john-doe/k3s-tools/main/install.sh
```

변수:
- `{USERNAME}`: GitHub 사용자명 (예: john-doe)
- `{REPO}`: 저장소명 (예: k3s-tools)
- `{FILENAME}`: 파일명 (예: install.sh)

---

## 📱 휴대폰/PC에서 바로 보기

### README.md 예시 내용

```markdown
# K3s 라즈베리파이 클러스터 모니터링 도구

라즈베리파이 K3s 클러스터를 쉽게 모니터링하는 도구 모음입니다.

## 🚀 빠른 시작

라즈베리파이의 마스터 노드에서:

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/install.sh | bash
\`\`\`

## 📥 다운로드

- [빠른 상태 확인](https://raw.githubusercontent.com/your-username/k3s-tools/main/quick-status.sh)
- [실시간 모니터링](https://raw.githubusercontent.com/your-username/k3s-tools/main/realtime-monitor.sh)
- [상세 진단](https://raw.githubusercontent.com/your-username/k3s-tools/main/cluster-diagnostics.sh)

## 📖 가이드

- [빠른 시작 가이드](quick-start.md)
- [모니터링 완전 가이드](monitoring-guide.md)
- [권한 문제 해결](permission-fix.md)

## 📝 라이선스

MIT
```

---

## 💾 로컬 설정 (회사 네트워크 등)

GitHub 접근이 안 되는 경우:

### 1단계: 마스터 노드에서 HTTP 서버 시작

```bash
# 마스터 노드에 파일 복사
cd ~/k3s-monitor

# Python 3 HTTP 서버 시작
python3 -m http.server 8000
```

### 2단계: 다른 노드에서 다운로드

```bash
# worker 노드에서
mkdir -p ~/k3s-monitor && cd ~/k3s-monitor
curl http://master-ip:8000/quick-status.sh -O
chmod +x quick-status.sh
./quick-status.sh
```

---

## 🔐 HTTPS/SSL 설정 (선택사항)

더 안전하게 하려면:

```bash
# Python SSL 서버
cd ~/k3s-monitor
python3 -m http.server 8443 --cgi &

# 또는 nginx 사용
sudo apt install nginx
sudo systemctl start nginx

# /etc/nginx/sites-available/default에 설정 추가
location /k3s-tools {
    alias /home/pi/k3s-monitor;
}
```

---

## 📊 별칭 설정 (convenience)

한번 설치 후 편하게 사용하려면:

```bash
# ~/.bashrc에 추가
echo 'export PATH="$PATH:$HOME/k3s-monitor"' >> ~/.bashrc
echo 'alias k3s-quick="$HOME/k3s-monitor/quick-status.sh"' >> ~/.bashrc
echo 'alias k3s-monitor="$HOME/k3s-monitor/realtime-monitor.sh"' >> ~/.bashrc

# 적용
source ~/.bashrc

# 이제 바로 사용 가능
k3s-quick
k3s-monitor
```

---

## 🆘 문제 해결

### curl이 없는 경우
```bash
# wget으로 대체
wget -O - https://raw.githubusercontent.com/.../install.sh | bash

# 또는 설치
sudo apt update && sudo apt install curl -y
```

### 다운로드 속도가 느린 경우
```bash
# GitHub 대신 로컬 서버 사용
curl http://master-ip:8000/install.sh | bash
```

### 권한 문제
```bash
# 자동 해결 스크립트 실행
sudo bash fix-k3s-permissions.sh
```

---

## ✅ 최종 체크리스트

- [ ] GitHub 저장소 생성
- [ ] 모든 파일 업로드
- [ ] 라즈베리파이에서 설치 명령어 실행
- [ ] 권한 문제 자동 해결
- [ ] 클러스터 상태 확인
- [ ] 모니터링 시작!

---

## 🎉 완료!

이제 다음 명령어로 클러스터를 모니터링할 수 있습니다:

```bash
cd ~/k3s-monitor
./quick-status.sh        # 빠른 확인
./realtime-monitor.sh    # 실시간 모니터링
./cluster-diagnostics.sh # 상세 진단
```

---

## 📞 추가 도움

문제가 있으면:

1. `permission-fix.md` 참고
2. `monitoring-guide.md` 확인
3. `./cluster-diagnostics.sh` 실행해서 상세 로그 확인

---

**준비되셨나요? 지금 설치하세요!** 🚀

```bash
curl -fsSL https://raw.githubusercontent.com/your-username/k3s-tools/main/install.sh | bash
```
