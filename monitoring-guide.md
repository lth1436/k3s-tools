# K3s 라즈베리파이 클러스터 모니터링 완전 가이드
## 간단한 명령어로 클러스터 상태 확인하기

---

## 📊 목차
1. [즉시 확인하기](#즉시-확인하기-5분)
2. [기본 상태 확인](#기본-상태-확인-명령어)
3. [상세 진단](#상세-진단)
4. [성능 벤치마크](#성능-벤치마크)
5. [자동화 스크립트](#자동화-스크립트)
6. [고급 모니터링](#고급-모니터링-대시보드)

---

## 🚀 즉시 확인하기 (5분)

### 단계 1: 마스터 노드에 접속
```bash
ssh pi@<master-ip>
# 또는
ssh pi@master  # hostname으로 접속 (설정되어 있다면)
```

### 단계 2: 클러스터 상태 한눈에 보기
```bash
# 가장 중요한 3개 명령어
kubectl get nodes                 # 모든 노드 상태
kubectl get pods --all-namespaces # 모든 파드 상태
kubectl top nodes                 # CPU/메모리 사용률
```

### 단계 3: 결과 해석
```
예상 출력:

$ kubectl get nodes
NAME      STATUS   ROLES                  AGE    VERSION
master    Ready    control-plane,master   10d    v1.24.0
worker1   Ready    <none>                 10d    v1.24.0
worker2   Ready    <none>                 10d    v1.24.0

$ kubectl top nodes
NAME      CPU(cores)   CPU%   MEMORY(Mi)   MEMORY%
master    245m         24%    512Mi        51%
worker1   150m         15%    256Mi        25%
worker2   180m         18%    384Mi        38%
```

✅ **STATUS = Ready** = 정상
✅ **CPU% < 80%, MEMORY% < 80%** = 정상

---

## ✅ 기본 상태 확인 명령어

### 1️⃣ 노드 상태 확인

#### 전체 노드 목록
```bash
kubectl get nodes
```
출력 항목:
- **NAME**: 노드 이름
- **STATUS**: Ready (정상) / NotReady (문제)
- **ROLES**: master, worker 등
- **AGE**: 클러스터 참여 기간
- **VERSION**: Kubernetes 버전

#### 상세 노드 정보
```bash
kubectl get nodes -o wide
```
추가 정보:
- **INTERNAL-IP**: 노드의 내부 IP
- **OS-IMAGE**: 운영 체제

#### 특정 노드 상세 정보
```bash
kubectl describe node master

# 출력 항목:
# - Conditions: Ready, MemoryPressure, DiskPressure 등
# - Capacity: CPU, 메모리, 디스크 용량
# - Allocatable: 할당 가능한 리소스
# - Pods: 실행 중인 파드 목록
```

---

### 2️⃣ 파드(Pod) 상태 확인

#### 모든 파드 보기
```bash
# 모든 네임스페이스의 파드 확인
kubectl get pods --all-namespaces

# 또는 짧은 형태
kubectl get pods -A
```

예상 출력:
```
NAMESPACE     NAME                     READY  STATUS   RESTARTS  AGE
kube-system   coredns-76bff7d4c-j8d4w  1/1    Running  0         10d
kube-system   local-path-provisioner   1/1    Running  0         10d
default       my-app-5d4b6c8f9         1/1    Running  2         5d
```

#### 특정 네임스페이스의 파드만 보기
```bash
kubectl get pods -n kube-system          # 시스템 파드
kubectl get pods -n default              # 기본 네임스페이스
```

#### 파드 상세 정보
```bash
kubectl describe pod <pod-name> -n <namespace>

# 예시:
kubectl describe pod coredns-76bff7d4c-j8d4w -n kube-system
```

#### 파드 로그 확인
```bash
# 실시간 로그
kubectl logs -f <pod-name> -n <namespace>

# 최근 100줄
kubectl logs <pod-name> -n <namespace> --tail=100
```

---

### 3️⃣ CPU/메모리 사용률 확인

#### 노드별 리소스 사용량
```bash
kubectl top nodes
```
출력:
```
NAME      CPU(cores)   CPU%   MEMORY(Mi)   MEMORY%
master    245m         24%    512Mi        51%
worker1   150m         15%    256Mi        25%
worker2   180m         18%    384Mi        38%
```

**용량 단위 설명:**
- `m` = 밀리코어 (1000m = 1 CPU)
- `Mi` = 메비바이트

#### 파드별 리소스 사용량
```bash
kubectl top pods --all-namespaces

# 특정 네임스페이스만
kubectl top pods -n kube-system
```

---

### 4️⃣ 클러스터 전체 정보

#### 클러스터 정보
```bash
kubectl cluster-info
```
출력:
```
Kubernetes control plane is running at https://192.168.1.100:6443
CoreDNS is running at https://192.168.1.100:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'
```

#### 버전 확인
```bash
kubectl version

# 출력 예:
# Client Version: version.Info{Major:"1", Minor:"24"}
# Server Version: version.Info{Major:"1", Minor:"24"}
```

#### 클러스터 리소스 요약
```bash
kubectl api-resources
```

---

## 🔍 상세 진단

### 1️⃣ 문제가 있는 노드 찾기

#### NotReady 상태 노드 확인
```bash
kubectl get nodes | grep NotReady

# 문제 노드의 상세 정보
kubectl describe node <노드이름>

# 주의사항 확인
kubectl describe node <노드이름> | grep -A 10 Conditions
```

예상 출력:
```
Conditions:
  Type                 Status  LastHeartbeatTime           LastTransitionTime
  Ready                False   2024-05-16T10:30:00Z        2024-05-16T10:15:00Z
  MemoryPressure       True    2024-05-16T10:30:00Z        2024-05-16T09:50:00Z
  DiskPressure         False   2024-05-16T10:30:00Z        2024-05-16T09:50:00Z
```

**해석:**
- Ready: False → 노드 문제
- MemoryPressure: True → 메모리 부족
- DiskPressure: True → 디스크 부족

#### 해결책
```bash
# 1. 해당 노드에 SSH 접속
ssh pi@<노드IP>

# 2. 시스템 상태 확인
df -h              # 디스크 용량
free -h            # 메모리
top                # 프로세스

# 3. K3s 서비스 재시작 (필요시)
sudo systemctl restart k3s-agent  # worker 노드
# 또는
sudo systemctl restart k3s        # master 노드

# 4. 다시 Ready 상태인지 확인
kubectl get nodes
```

---

### 2️⃣ 문제가 있는 파드 찾기

#### 실패한 파드 찾기
```bash
# 상태가 Running이 아닌 파드 찾기
kubectl get pods --all-namespaces | grep -v Running

# 또는
kubectl get pods -A --field-selector=status.phase!=Running
```

상태별 의미:
- **Pending**: 시작 대기 중
- **Running**: 정상 실행 중
- **Succeeded**: 성공적으로 완료
- **Failed**: 실패
- **Unknown**: 상태 불명

#### 실패한 파드 상세 확인
```bash
# 파드 설명 보기
kubectl describe pod <pod-name> -n <namespace>

# 파드 로그 보기
kubectl logs <pod-name> -n <namespace>

# 이전 파드 로그 (재시작된 경우)
kubectl logs <pod-name> -n <namespace> --previous
```

#### 파드 재시작
```bash
# 파드 삭제 (자동 재생성)
kubectl delete pod <pod-name> -n <namespace>

# Deployment의 모든 파드 재시작
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```

---

### 3️⃣ 이벤트 및 알람 확인

#### 클러스터 이벤트 보기
```bash
# 전체 이벤트
kubectl get events -A

# 최근 이벤트만
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# 경고 이벤트만
kubectl get events -A | grep Warning
```

예상 출력:
```
NAMESPACE   LAST SEEN   TYPE      REASON               OBJECT
default     1h          Warning   FailedScheduling     pod/my-app-xyz
kube-sys    2h          Warning   NodeNotReady         node/worker2
```

---

### 4️⃣ 네트워크 연결 확인

#### 노드 간 네트워크 테스트
```bash
# 마스터 노드에서 worker 노드에 핑
ping <worker-ip>

# 또는 kubectl로 실행
kubectl run -it --rm debug --image=busybox --restart=Never -- ping <worker-ip>
```

#### DNS 확인
```bash
# DNS 서비스 확인
kubectl get svc -n kube-system | grep dns

# DNS 동작 테스트
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

---

## 📈 성능 벤치마크

### 1️⃣ 각 노드의 상세 리소스 확인

#### 마스터 노드
```bash
ssh pi@master

# 1. CPU 정보
nproc                              # CPU 코어 수
cat /proc/cpuinfo                 # CPU 상세 정보

# 2. 메모리
free -h                            # 메모리 사용량
cat /proc/meminfo                 # 메모리 상세 정보

# 3. 디스크
df -h                              # 디스크 사용량
du -sh /var/lib/rancher           # K3s 데이터 크기

# 4. 프로세스
ps aux | grep k3s                 # K3s 프로세스
top -b -n 1 | head -20            # 상위 프로세스
```

#### 모든 worker 노드에서 동일하게 확인
```bash
for node in worker1 worker2; do
  echo "=== $node ==="
  ssh pi@$node "free -h && df -h"
done
```

---

### 2️⃣ 클러스터 성능 테스트

#### 간단한 로드 테스트
```bash
# 1. 테스트 애플리케이션 배포
kubectl create deployment load-test --image=nginx --replicas=3

# 2. 리소스 사용 모니터링
watch kubectl top pods

# 3. 완료 후 정리
kubectl delete deployment load-test
```

#### 네트워크 대역폭 테스트 (iperf3)
```bash
# 마스터 노드에서
ssh pi@master
iperf3 -s  # 서버 시작

# 다른 터미널에서 worker 노드에서
ssh pi@worker1
iperf3 -c <master-ip> -P 4 -t 30

# 결과 해석:
# Bitrate: Mbps (메가비트/초)
# 라즈베리파이는 보통 100Mbps (기가비트 이더넷) 또는 1Gbps
```

---

## 🤖 자동화 스크립트

### 1️⃣ 클러스터 상태 빠른 확인 스크립트

```bash
#!/bin/bash
# cluster-status.sh

echo "======================================"
echo "K3s 클러스터 상태 확인"
echo "======================================"
echo ""

# 1. 노드 상태
echo "✓ 노드 상태:"
kubectl get nodes -o wide
echo ""

# 2. 파드 상태
echo "✓ 파드 상태:"
kubectl get pods -A | head -20
echo ""

# 3. 리소스 사용량
echo "✓ 리소스 사용량:"
kubectl top nodes
echo ""

# 4. 문제 진단
echo "✓ 문제 진단:"
NotReadyNodes=$(kubectl get nodes | grep NotReady | wc -l)
FailedPods=$(kubectl get pods -A | grep -E "Failed|Error" | wc -l)

if [ "$NotReadyNodes" -eq 0 ]; then
  echo "✅ 모든 노드가 Ready 상태"
else
  echo "⚠️  Ready가 아닌 노드: $NotReadyNodes개"
fi

if [ "$FailedPods" -eq 0 ]; then
  echo "✅ 실패한 파드 없음"
else
  echo "⚠️  실패한 파드: $FailedPods개"
fi

echo ""
echo "======================================"
```

사용법:
```bash
# 실행 권한 부여
chmod +x cluster-status.sh

# 실행
./cluster-status.sh

# 반복 모니터링 (5초마다)
watch -n 5 ./cluster-status.sh
```

---

### 2️⃣ 모든 노드 상태 한번에 확인 스크립트

```bash
#!/bin/bash
# all-nodes-status.sh

echo "======================================"
echo "모든 노드 상태 확인"
echo "======================================"
echo ""

# 마스터에서 워커 노드 목록 가져오기
NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

for NODE in $NODES; do
  echo "📍 노드: $NODE"
  
  # SSH로 연결 가능한지 확인
  if ping -c 1 -W 1 $NODE &> /dev/null; then
    echo "  ✅ 네트워크: 연결됨"
  else
    echo "  ❌ 네트워크: 연결 안 됨"
    continue
  fi
  
  # kubectl로 상태 확인
  STATUS=$(kubectl get node $NODE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
  if [ "$STATUS" = "True" ]; then
    echo "  ✅ K3s 상태: Ready"
  else
    echo "  ❌ K3s 상태: NotReady"
  fi
  
  # 리소스 확인
  CPU=$(kubectl top node $NODE --no-headers | awk '{print $2}')
  MEMORY=$(kubectl top node $NODE --no-headers | awk '{print $4}')
  echo "  💾 CPU: $CPU / 메모리: $MEMORY"
  
  echo ""
done

echo "======================================"
```

---

### 3️⃣ 정기적 모니터링 스크립트 (30초마다)

```bash
#!/bin/bash
# continuous-monitor.sh

while true; do
  clear
  echo "======================================"
  echo "K3s 클러스터 모니터링 (실시간)"
  echo "업데이트 시간: $(date)"
  echo "======================================"
  echo ""
  
  # 노드 상태
  echo "📌 노드 상태:"
  kubectl get nodes
  echo ""
  
  # 파드 상태
  echo "📌 파드 상태:"
  kubectl get pods -A | grep -E "Running|Failed|Error|Pending" | head -10
  echo ""
  
  # 리소스 사용량
  echo "📌 리소스 사용량:"
  kubectl top nodes
  echo ""
  
  # 경고 이벤트
  echo "📌 최근 이벤트:"
  kubectl get events -A --sort-by='.lastTimestamp' | grep -E "Warning|Error" | tail -5
  echo ""
  
  echo "30초 후 새로고침... (Ctrl+C로 종료)"
  sleep 30
done
```

사용법:
```bash
chmod +x continuous-monitor.sh
./continuous-monitor.sh
```

---

## 🎯 고급 모니터링 (대시보드)

### 1️⃣ kubectl 대시보드 (웹 UI)

#### 설치
```bash
# Kubernetes 대시보드 설치
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 설치 확인
kubectl get pods -n kubernetes-dashboard
```

#### 접속
```bash
# 프록시 시작
kubectl proxy

# 웹 브라우저에서 열기
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

#### 토큰 얻기 (로그인 필요)
```bash
# 서비스 어카운트 토큰 조회
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

---

### 2️⃣ Metrics Server (리소스 모니터링)

K3s는 기본적으로 포함되어 있지만, 확인하려면:

```bash
# 메트릭 서버 확인
kubectl get deployment metrics-server -n kube-system

# 메트릭 데이터 확인 (약 1분 후)
kubectl top nodes
kubectl top pods -A
```

---

### 3️⃣ 간단한 모니터링 대시보드 설치 (선택사항)

#### Weave Scope (시각화 도구)
```bash
# 설치
kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# 접속
kubectl port-forward -n weave svc/weave-scope-app 4040:4040 --address 0.0.0.0

# 웹에서
# http://<master-ip>:4040
```

---

## 📋 일일 확인 체크리스트

### 매일 아침
```bash
# 1. 노드 상태 확인
kubectl get nodes

# 2. 파드 상태 확인
kubectl get pods -A | grep -E "Failed|Error|CrashLoop"

# 3. 리소스 확인
kubectl top nodes
kubectl top pods -A | sort -k3 -nr | head -10  # CPU 상위 10개

# 4. 디스크 공간 확인
for node in master worker1 worker2; do
  echo "=== $node ===" 
  ssh pi@$node "df -h /"
done
```

### 주간 점검
```bash
# 1. 클러스터 전체 이벤트
kubectl get events -A --sort-by='.lastTimestamp' | tail -50

# 2. 사용 리소스 트렌드
kubectl top nodes --sort-by=cpu
kubectl top pods -A --sort-by=memory | head -20

# 3. K3s 로그 확인
journalctl -u k3s -n 100 --no-pager  # master
journalctl -u k3s-agent -n 100 --no-pager  # worker
```

---

## 🚨 장애 대응 체크리스트

### 노드가 NotReady 상태
```bash
# 1. SSH 연결 확인
ssh pi@<node-ip>

# 2. 네트워크 확인
ping 8.8.8.8

# 3. 디스크 확인
df -h /

# 4. K3s 서비스 확인
sudo systemctl status k3s-agent

# 5. 재시작
sudo systemctl restart k3s-agent

# 6. 상태 확인
kubectl get nodes
```

### 파드가 자꾸 재시작됨 (CrashLoopBackOff)
```bash
# 1. 파드 정보
kubectl describe pod <pod-name> -n <namespace>

# 2. 로그 확인
kubectl logs <pod-name> -n <namespace> --previous

# 3. 이벤트 확인
kubectl describe pod <pod-name> -n <namespace> | grep Events -A 20

# 4. 파드 재생성
kubectl delete pod <pod-name> -n <namespace>
```

### 메모리 부족
```bash
# 1. 현재 사용량
kubectl top pods -A | sort -k3 -nr | head -20

# 2. 노드별 할당량
kubectl describe nodes | grep "Allocated resources" -A 5

# 3. 파드 삭제 또는 리소스 제한
kubectl set resources deployment <name> --limits=memory=256Mi
```

---

## 💡 유용한 kubectl 팁

### 짧은 명령어 (alias)
```bash
# ~/.bashrc에 추가
alias k='kubectl'
alias kgn='kubectl get nodes'
alias kgp='kubectl get pods -A'
alias ktn='kubectl top nodes'
alias ktp='kubectl top pods -A'

# 사용
source ~/.bashrc
k get nodes
ktn  # kubectl top nodes와 동일
```

### 실시간 모니터링
```bash
# 실시간 업데이트 (watch)
watch kubectl get nodes
watch kubectl top nodes

# 또는 --watch 플래그
kubectl get nodes --watch
```

### 쉘 자동완성
```bash
# bash 자동완성
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl

# 재로그인 후 사용
kubectl get no<TAB>  # 자동완성
```

---

## 📚 참고 자료

### 공식 문서
- K3s 공식: https://docs.k3s.io/
- Kubernetes 공식: https://kubernetes.io/docs/

### 유용한 명령어 한눈에 보기
```bash
# 가장 자주 사용하는 명령어 TOP 10
kubectl get nodes                    # 노드 확인
kubectl get pods -A                  # 파드 확인
kubectl top nodes                    # CPU/메모리 확인
kubectl describe node <name>         # 노드 상세 정보
kubectl logs -f <pod> -n <ns>       # 실시간 로그
kubectl exec -it <pod> -n <ns> bash # 파드 진입
kubectl apply -f deployment.yaml     # 배포
kubectl delete pod <name> -n <ns>   # 파드 삭제
kubectl get events -A                # 이벤트 확인
kubectl cluster-info                 # 클러스터 정보
```

---

**다음 단계:**
1. ✅ `kubectl get nodes`로 모든 노드가 Ready인지 확인
2. ✅ `kubectl get pods -A`로 파드 상태 확인
3. ✅ `kubectl top nodes`로 리소스 사용 확인
4. ✅ 문제가 있으면 "상세 진단" 섹션 참조

**질문이 있으면 언제든 물어봐주세요!** 🚀
