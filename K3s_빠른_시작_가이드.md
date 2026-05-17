# K3s 클러스터 모니터링 - 빠른 시작 가이드

## 🚀 5분 안에 시작하기

### 1단계: 마스터 노드에 접속
```bash
ssh pi@<master-ip>
# 또는
ssh pi@master
```

### 2단계: 클러스터 상태 확인 (가장 중요한 3가지)
```bash
# 모든 노드가 Ready인지 확인
kubectl get nodes

# 파드가 정상적으로 실행 중인지 확인
kubectl get pods -A

# CPU와 메모리 사용률 확인
kubectl top nodes
```

### 3단계: 문제 확인
```bash
# 문제가 있는 파드 찾기
kubectl get pods -A | grep -E "Failed|Error|CrashLoop"

# 최근 에러 이벤트 확인
kubectl get events -A | grep Error
```

---

## 📊 3가지 모니터링 방법

### 방법 1️⃣: 빠른 상태 확인 (1분)
```bash
# 다운로드
wget https://your-server/quick-status.sh
chmod +x quick-status.sh

# 실행
./quick-status.sh
```
✅ 상황을 한눈에 파악  
✅ 문제점 즉시 확인  
⏱️ 소요시간: 1분

---

### 방법 2️⃣: 실시간 모니터링 (지속)
```bash
# 다운로드
wget https://your-server/realtime-monitor.sh
chmod +x realtime-monitor.sh

# 실행 (10초마다 업데이트)
./realtime-monitor.sh

# 또는 5초마다 업데이트
./realtime-monitor.sh 5
```
✅ 실시간 대시보드  
✅ 건강도 점수 표시  
✅ Ctrl+C로 종료  
⏱️ 지속적 모니터링

---

### 방법 3️⃣: 상세 진단 (상황 분석)
```bash
# 다운로드
wget https://your-server/cluster-diagnostics.sh
chmod +x cluster-diagnostics.sh

# 실행 (10-15분 소요)
./cluster-diagnostics.sh

# 로그 파일에 상세 정보 저장됨
```
✅ 전체 시스템 진단  
✅ 로그 파일 생성  
✅ 상세 문제 분석  
⏱️ 소요시간: 10-15분

---

## 🎯 상황별 명령어

### 상황 1: "클러스터가 정상 작동하나?"
```bash
# 1단계: 노드 확인
kubectl get nodes

# 2단계: 파드 확인
kubectl get pods -A

# 3단계: 리소스 확인
kubectl top nodes

# ✅ 모두 정상이면 OK!
```

### 상황 2: "특정 파드가 자꾸 재시작돼"
```bash
# 파드 상태 확인
kubectl describe pod <pod-name> -n <namespace>

# 로그 확인
kubectl logs <pod-name> -n <namespace> --tail=50

# 이전 로그도 확인 (재시작 후)
kubectl logs <pod-name> -n <namespace> --previous

# 파드 재생성
kubectl delete pod <pod-name> -n <namespace>
```

### 상황 3: "한 노드가 응답이 없어"
```bash
# SSH로 직접 접속
ssh pi@<node-ip>

# 서비스 상태 확인
sudo systemctl status k3s-agent

# 디스크/메모리 확인
df -h && free -h

# K3s 서비스 재시작
sudo systemctl restart k3s-agent

# 상태 다시 확인
kubectl get nodes
```

### 상황 4: "메모리/CPU가 부족해"
```bash
# 리소스 사용 많은 파드 확인
kubectl top pods -A --sort-by=memory | head -10
kubectl top pods -A --sort-by=cpu | head -10

# 특정 파드 리소스 제한 설정
kubectl set resources deployment <name> --limits=memory=256Mi --limits=cpu=500m

# 또는 파드 삭제
kubectl delete pod <pod-name> -n <namespace>
```

### 상황 5: "DNS가 안 돼"
```bash
# DNS 서비스 확인
kubectl get svc -n kube-system | grep dns

# DNS 파드 확인
kubectl get pods -n kube-system | grep coredns

# DNS 테스트
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

---

## 📋 일일 체크리스트

### 아침 확인 (5분)
```bash
# 1. 노드 상태
kubectl get nodes

# 2. 문제 파드
kubectl get pods -A | grep -E "Failed|Error|Pending"

# 3. 이벤트
kubectl get events -A --sort-by='.lastTimestamp' | tail -5
```

### 주간 점검 (30분)
```bash
# 1. 스크립트로 전체 진단
./cluster-diagnostics.sh

# 2. 로그 파일 검토
cat cluster-diagnostics-*.log

# 3. 리소스 사용 추이 파악
kubectl top pods -A | sort -k3 -nr | head -20
```

---

## 🔧 자동 모니터링 (선택사항)

### cron으로 주기적 점검
```bash
# crontab 열기
crontab -e

# 아래 줄 추가:
# 매일 08:00에 진단 실행
0 8 * * * /home/pi/cluster-diagnostics.sh

# 매 10분마다 상태 확인
*/10 * * * * /home/pi/quick-status.sh >> /tmp/k3s-status.log 2>&1
```

### systemd로 지속 모니터링
```bash
# 서비스 파일 생성
sudo nano /etc/systemd/system/k3s-monitor.service

# 다음 내용 입력:
[Unit]
Description=K3s Cluster Monitor
After=network.target

[Service]
Type=simple
ExecStart=/home/pi/realtime-monitor.sh
User=pi
Restart=always

[Install]
WantedBy=multi-user.target

# 저장하고:
sudo systemctl daemon-reload
sudo systemctl enable k3s-monitor
sudo systemctl start k3s-monitor
```

---

## 📊 결과 해석

### kubectl get nodes 해석
```
NAME      STATUS   ROLES                  AGE    VERSION
master    Ready    control-plane,master   10d    v1.24.0
worker1   Ready    <none>                 10d    v1.24.0

✓ STATUS = Ready → 정상
✗ STATUS = NotReady → 문제
✗ STATUS = Unknown → 심각한 문제
```

### kubectl top nodes 해석
```
NAME      CPU(cores)   CPU%   MEMORY(Mi)   MEMORY%
master    245m         24%    512Mi        51%
worker1   150m         15%    256Mi        25%

✓ CPU% < 80%, MEMORY% < 80% → 정상
⚠ CPU% 60-80%, MEMORY% 60-80% → 주의
✗ CPU% > 80%, MEMORY% > 80% → 위험
```

### kubectl get pods 상태 해석
```
Running    → 정상 실행 중
Pending    → 시작 대기 (리소스 부족일 수 있음)
Failed     → 파드 실패 (로그 확인)
Error      → 에러 발생 (로그 확인)
CrashLoop  → 계속 재시작 (무한 루프)
```

---

## 🆘 문제 해결 플로우

```
클러스터 확인
    ↓
kubectl get nodes
    ↓
NotReady? ──→ SSH 접속 → systemctl restart → 확인
    ↓ No
kubectl get pods -A
    ↓
Failed? ──→ kubectl logs → 원인 파악 → 수정 또는 재생성
    ↓ No
kubectl top nodes
    ↓
리소스부족? ──→ 파드 정리 또는 확장
    ↓ No
✅ 정상!
```

---

## 💡 유용한 팁

### 짧은 명령어 (Alias) 설정
```bash
# ~/.bashrc에 추가
alias k='kubectl'
alias kn='kubectl get nodes'
alias kp='kubectl get pods -A'
alias kt='kubectl top nodes'
alias ke='kubectl get events -A'

# 적용
source ~/.bashrc
```

### 실시간 모니터링 (watch)
```bash
# 노드 상태 실시간
watch kubectl get nodes

# 리소스 사용 실시간
watch kubectl top nodes

# 2초마다 업데이트
watch -n 2 kubectl top pods -A
```

### 선택적 필드로 출력
```bash
# 특정 정보만 보기
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get pods -A -o jsonpath='{.items[*].metadata.name}'

# 커스텀 출력
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[?(@.type==\"Ready\")].status
```

---

## 📚 다음 단계

1. **스크립트 다운로드**
   - quick-status.sh (빠른 확인)
   - realtime-monitor.sh (실시간)
   - cluster-diagnostics.sh (상세 진단)

2. **실행 권한 부여**
   ```bash
   chmod +x *.sh
   ```

3. **첫 실행**
   ```bash
   ./quick-status.sh
   ```

4. **필요에 따라 사용**
   - 일일: quick-status.sh
   - 모니터링: realtime-monitor.sh
   - 문제 시: cluster-diagnostics.sh

---

## 🆘 추가 도움

### 공식 문서
- K3s: https://docs.k3s.io/
- Kubernetes: https://kubernetes.io/docs/

### 자주 사용하는 명령어
```bash
# 노드/파드 확인
kubectl get nodes
kubectl get pods -A
kubectl get pods -n <namespace>

# 상세 정보
kubectl describe node <name>
kubectl describe pod <pod-name> -n <namespace>

# 로그 확인
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>  # 실시간

# 리소스
kubectl top nodes
kubectl top pods -A
kubectl get events -A

# 관리
kubectl delete pod <pod-name> -n <namespace>
kubectl exec -it <pod-name> -n <namespace> bash
```

---

**지금 바로 시작하세요!** 🚀

```bash
./quick-status.sh
```

아무 문제가 없으면 축하합니다! 클러스터가 정상 작동 중입니다. ✅
