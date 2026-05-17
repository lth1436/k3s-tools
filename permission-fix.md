# K3s kubectl 권한 문제 해결

## 🔴 문제 상황
```
WARN[0000] Unable to read /etc/rancher/k3s/k3s.yaml
error: error loading config file "/etc/rancher/k3s/k3s.yaml": permission denied
```

→ `/etc/rancher/k3s/k3s.yaml` 파일에 접근 권한이 없음

---

## ✅ 해결 방법 (3가지)

### 방법 1️⃣: sudo 사용 (가장 간단, 즉시 효과)

모든 kubectl 명령어 앞에 `sudo` 붙이기:

```bash
# 현재 (에러)
kubectl get nodes
# → permission denied

# 수정 (정상)
sudo kubectl get nodes
# → 작동!
```

**모든 kubectl 명령어:**
```bash
sudo kubectl get nodes
sudo kubectl get pods -A
sudo kubectl top nodes
sudo kubectl describe pod <name> -n <namespace>
sudo kubectl logs <pod-name> -n <namespace>
```

**스크립트도 sudo로 실행:**
```bash
sudo ./quick-status.sh
sudo ./realtime-monitor.sh
sudo ./cluster-diagnostics.sh
```

---

### 방법 2️⃣: 권한 파일 수정 (권장, 영구 해결)

#### 단계 1: 파일 권한 확인
```bash
ls -la /etc/rancher/k3s/k3s.yaml
```

출력 예시:
```
-rw------- 1 root root 2947 May 16 10:00 /etc/rancher/k3s/k3s.yaml
# ↑ rw------- = root만 읽기/쓰기 가능
```

#### 단계 2: 권한 변경 (선택 1)
```bash
# 현재 사용자가 읽을 수 있도록 권한 변경
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

**결과:**
```bash
ls -la /etc/rancher/k3s/k3s.yaml
# -rw-r--r-- 1 root root 2947 May 16 10:00 /etc/rancher/k3s/k3s.yaml
```

이제 `sudo` 없이 사용 가능:
```bash
kubectl get nodes  # 정상!
```

---

### 방법 3️⃣: 소유자 변경 (더 좋은 해결)

#### 단계 1: 현재 사용자 확인
```bash
whoami
# 출력: pi
```

#### 단계 2: 파일 소유자 변경
```bash
# 방법 A: 파일만 변경
sudo chown pi:pi /etc/rancher/k3s/k3s.yaml

# 또는 방법 B: 전체 디렉토리 변경 (더 안전)
sudo chown -R pi:pi /etc/rancher/k3s/
```

#### 단계 3: 확인
```bash
ls -la /etc/rancher/k3s/k3s.yaml
# -rw-r----- 1 pi pi 2947 May 16 10:00 /etc/rancher/k3s/k3s.yaml
# ↑ pi가 소유자

# 테스트
kubectl get nodes  # 정상!
```

---

### 방법 4️⃣: 환경 변수 설정 (대체 방법)

K3s 설치 시 KUBECONFIG 설정:

```bash
# 1. 복사본 생성 (현재 사용자 소유)
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown pi:pi ~/.kube/config
chmod 600 ~/.kube/config

# 2. 환경 변수 설정
export KUBECONFIG=~/.kube/config

# 3. .bashrc에 추가해서 영구 설정
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
source ~/.bashrc

# 4. 테스트
kubectl get nodes  # 정상!
```

---

## 🎯 추천: 방법 3 (영구 해결)

가장 깔끔한 방법입니다:

```bash
# 1. 현재 사용자 확인
whoami

# 2. 권한 변경
sudo chown -R pi:pi /etc/rancher/k3s/

# 3. 검증
kubectl get nodes

# 4. 스크립트 실행 (sudo 없이)
./quick-status.sh
```

---

## 🔄 K3s 재설치 시 미리 설정

K3s를 다시 설치할 계획이라면, 설치 명령어에 옵션 추가:

```bash
# K3s 마스터 노드 설치 (권한 설정 포함)
curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644 \
  --write-kubeconfig-group pi

# 또는 K3s 에이전트 (worker 노드)
curl -sfL https://get.k3s.io | K3S_URL=https://master-ip:6443 \
  K3S_TOKEN=<token> sh -s - \
  --write-kubeconfig-mode 644 \
  --write-kubeconfig-group pi
```

이렇게 설치하면 처음부터 권한이 올바르게 설정됩니다.

---

## 📋 선택 가이드

| 방법 | 설명 | 장점 | 단점 |
|------|------|------|------|
| **방법 1** (sudo) | 모든 명령어 앞에 sudo | 즉시 사용 가능 | 매번 치기 번거로움 |
| **방법 2** (chmod) | 파일 읽기 권한 변경 | 간단 | 보안 약화 |
| **방법 3** (chown) | **소유자 변경** | **가장 권장** | 약간의 권한 관리 필요 |
| **방법 4** (KUBECONFIG) | 복사본 사용 | 안전 | 파일 복제 필요 |

---

## 🚀 지금 바로 해결하기 (3단계)

### Step 1: 현재 사용자 확인
```bash
whoami
```

### Step 2: 권한 변경
```bash
sudo chown -R pi:pi /etc/rancher/k3s/
```

### Step 3: 검증
```bash
kubectl get nodes
```

**완료!** ✅

---

## 🆘 여전히 안 되면?

### 문제 1: "Still permission denied"

```bash
# 1. 파일 권한 상세 확인
ls -la /etc/rancher/k3s/k3s.yaml

# 2. 더 강한 권한 설정
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sudo chown pi:pi /etc/rancher/k3s/k3s.yaml

# 3. 다시 테스트
kubectl get nodes
```

### 문제 2: "kubeconfig not found"

```bash
# 1. KUBECONFIG 경로 확인
echo $KUBECONFIG

# 2. 설정되지 않았으면 수동 설정
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes

# 3. 영구 설정
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
source ~/.bashrc
```

### 문제 3: "K3s 서비스가 실행 중이 아님"

```bash
# 마스터 노드에서
sudo systemctl status k3s

# Worker 노드에서
sudo systemctl status k3s-agent

# 실행 중이 아니면 시작
sudo systemctl start k3s      # 마스터
sudo systemctl start k3s-agent # worker

# 상태 확인
sudo systemctl status k3s
```

---

## 📊 스크립트 실행 방법 수정

### Before (에러)
```bash
./quick-status.sh
# WARN[0000] Unable to read...
```

### After (수정)
```bash
# 옵션 1: sudo 사용
sudo ./quick-status.sh

# 옵션 2: 권한 해결 후 (권장)
./quick-status.sh  # sudo 없이 가능!
```

---

## 💡 스크립트에 sudo 자동 추가

스크립트 안에서 자동으로 sudo를 사용하도록 수정하려면:

```bash
# 스크립트 파일 열기
nano quick-status.sh

# 다음 줄을 찾아서:
kubectl get nodes

# 이렇게 변경:
sudo kubectl get nodes

# 또는 모든 kubectl을 sudo kubectl로 변경하려면:
sed -i 's/kubectl /sudo kubectl /g' quick-status.sh
```

---

## ✨ 최종 체크리스트

- [ ] 현재 사용자 확인: `whoami`
- [ ] 권한 변경: `sudo chown -R pi:pi /etc/rancher/k3s/`
- [ ] 검증: `kubectl get nodes`
- [ ] 스크립트 실행: `./quick-status.sh`
- [ ] ✅ 성공!

---

## 📞 빠른 참조

```bash
# 권한 문제 해결 (한 줄)
sudo chown -R pi:pi /etc/rancher/k3s/ && kubectl get nodes

# 권한 확인
ls -la /etc/rancher/k3s/k3s.yaml

# 소유자 확인
stat /etc/rancher/k3s/k3s.yaml

# K3s 서비스 상태
sudo systemctl status k3s

# K3s 서비스 재시작
sudo systemctl restart k3s

# 모든 kubectl 명령어에 sudo 추가 (임시)
alias kubectl='sudo kubectl'
```

---

**이제 문제가 해결되었나요?** 

`kubectl get nodes`를 실행해보세요! ✅
