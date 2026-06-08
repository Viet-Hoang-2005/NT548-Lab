# Lab 2 - Câu 3: CI/CD microservices bằng GitHub Actions, Docker, k3s, SonarQube và Trivy

Phần này dùng GitHub Actions như một dịch vụ CI/CD tương tự Jenkins để tự động hóa quá trình build, test, kiểm tra chất lượng mã nguồn, scan bảo mật Docker image và deploy ứng dụng microservices lên cụm k3s đã tạo bằng CloudFormation ở Lab 2 câu 2.

## Lý do chọn GitHub Actions thay Jenkins

- Repo đang được quản lý trên GitHub, nên workflow CI/CD nằm trực tiếp cùng source code.
- Không cần triển khai và vận hành Jenkins server riêng.
- GitHub Actions hỗ trợ sẵn matrix job, secrets, GitHub Container Registry và self-hosted runner.
- Vẫn đáp ứng yêu cầu "Jenkins hoặc một dịch vụ tương tự" vì pipeline có đủ các bước build, test, scan và deploy lên Kubernetes.

## Microservices được tái sử dụng

Thay vì tạo service demo mới, phần này tái sử dụng 3 service từ project SageLMS:

| Service | Thư mục | Port | Vai trò |
| --- | --- | --- | --- |
| Gateway | `services/gateway` | `8080` | API Gateway, route request đến các service nội bộ |
| Auth Service | `services/auth-service` | `8081` | Đăng nhập, JWT, user/profile |
| Course Service | `services/course-service` | `8082` | Quản lý khóa học và enrollment |
| PostgreSQL | `k8s/microservices/postgres-*` | `5432` | Database nội bộ cho Auth và Course |

Không dùng `apps/web` trong lab này vì frontend Node thường có dependency surface lớn hơn và dễ phát sinh cảnh báo Trivy không cần thiết cho mục tiêu CI/CD backend.

## Kiến trúc triển khai

```text
GitHub push
  -> GitHub Actions matrix job
     -> Maven unit test cho gateway/auth-service/course-service
     -> SonarQube hoặc SonarCloud scan nếu có token
     -> Docker build từng service
     -> Trivy scan từng image
     -> Push image lên GHCR
  -> Self-hosted runner trên EC2 master
     -> kubectl deploy PostgreSQL
     -> kubectl deploy auth-service, course-service, gateway
     -> smoke test gateway health endpoint

Internet
  -> ALB :80
  -> k3s worker NodePort :30080
  -> gateway Service :80
  -> gateway Pod :8080
  -> auth-service/course-service ClusterIP
  -> postgres ClusterIP
```

Hạ tầng được dùng lại từ câu 2:

- Public EC2 master chạy k3s server/control-plane.
- Hai private EC2 worker chạy k3s agent.
- ALB forward HTTP port `80` vào worker NodePort `30080`.
- Security Group đã mở luồng cần thiết cho k3s và NodePort.

## Cấu trúc source

```text
services/
|-- gateway/
|-- auth-service/
`-- course-service/

k8s/microservices/
|-- namespace.yaml
|-- postgres-deployment.yaml
|-- postgres-service.yaml
|-- auth-configmap.yaml
|-- auth-deployment.yaml
|-- auth-service.yaml
|-- course-configmap.yaml
|-- course-deployment.yaml
|-- course-service.yaml
|-- gateway-configmap.yaml
|-- gateway-deployment.yaml
`-- gateway-service.yaml

.github/workflows/microservices-cicd.yml
sonar-project.properties
```

## Workflow CI/CD

File workflow:

```text
.github/workflows/microservices-cicd.yml
```

Pipeline có 2 nhóm job chính:

1. `build-test-scan`
   - Chạy dạng matrix cho `gateway`, `auth-service`, `course-service`.
   - Setup Java 17 và cache Maven.
   - Chạy unit test bằng Maven:

```bash
./mvnw -B test --no-transfer-progress
```

   - Chạy SonarQube/SonarCloud nếu repo có secret `SONAR_TOKEN`.
   - Build Docker image cho từng service.
   - Scan image bằng Trivy, fail nếu có lỗ hổng `HIGH` hoặc `CRITICAL`.
   - Push image lên GHCR theo format:

```text
ghcr.io/<owner-lowercase>/<repo-lowercase>/<service-name>:<commit-sha>
```

2. `deploy-k3s`
   - Chạy trên self-hosted runner đặt ở EC2 master.
   - Xóa service demo cũ nếu còn giữ NodePort `30080`.
   - Tạo namespace `microservices`.
   - Tạo GHCR pull secret.
   - Deploy PostgreSQL trước.
   - Deploy `auth-service`, `course-service`, `gateway`.
   - Chờ rollout và chạy smoke test:

```bash
curl -fsS http://gateway/actuator/health
```

## GitHub secrets và variables

Workflow cần quyền mặc định của `GITHUB_TOKEN` để push/pull image GHCR trong cùng repo.

Nếu package GHCR để private lâu dài, nên tạo thêm PAT có quyền `read:packages` và dùng secret riêng như `GHCR_PAT`. Với lab, `GITHUB_TOKEN` đủ để build và deploy ngay trong workflow.

Các secret ứng dụng không được commit vào repo. Deploy job tạo Kubernetes Secret từ GitHub Secrets:

| Tên GitHub Secret | Dùng cho |
| --- | --- |
| `SAGELMS_DB_PASSWORD` | Password PostgreSQL và password app dùng để kết nối DB |
| `SAGELMS_JWT_SECRET` | Secret ký/verify JWT |
| `SAGELMS_GATEWAY_SHARED_SECRET` | Secret để gateway xác thực request nội bộ đến service |
| `SAGELMS_INTERNAL_API_SECRET` | Secret cho các API nội bộ giữa service |

Ví dụ tạo secret bằng GitHub CLI:

```powershell
gh secret set SAGELMS_DB_PASSWORD
gh secret set SAGELMS_JWT_SECRET
gh secret set SAGELMS_GATEWAY_SHARED_SECRET
gh secret set SAGELMS_INTERNAL_API_SECRET
```

Nếu muốn tích hợp Sonar:

| Tên | Loại | Mô tả |
| --- | --- | --- |
| `SONAR_TOKEN` | Secret | Token để upload kết quả scan lên SonarQube/SonarCloud |
| `SONAR_HOST_URL` | Secret | URL SonarQube self-hosted, ví dụ `http://<host>:9000`; nếu dùng SonarCloud có thể bỏ qua |
Nếu dùng SonarCloud thay vì SonarQube self-hosted, có thể bổ sung `-Dsonar.organization=<organization-key>` trong bước Sonar của workflow.

Nếu chưa cấu hình `SONAR_TOKEN`, workflow sẽ skip bước Sonar và vẫn chạy các bước còn lại.

## Cài self-hosted runner trên EC2 master

SSH vào master:

```bash
ssh -i group7-cfn-keypair.pem ubuntu@<MASTER_PUBLIC_IP>
```

Vào GitHub repo:

```text
Settings -> Actions -> Runners -> New self-hosted runner -> Linux x64
```

Chạy các lệnh GitHub cung cấp, ví dụ:

```bash
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64.tar.gz -L <RUNNER_DOWNLOAD_URL>
tar xzf ./actions-runner-linux-x64.tar.gz
./config.sh --url https://github.com/<OWNER>/<REPO> --token <RUNNER_TOKEN>
```

Cài runner thành service để không phải giữ terminal mở:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

## Kiểm tra local

Chạy test từng service trên máy local:

```powershell
cd services/gateway
.\mvnw.cmd -B test --no-transfer-progress

cd ..\auth-service
.\mvnw.cmd -B test --no-transfer-progress

cd ..\course-service
.\mvnw.cmd -B test --no-transfer-progress
```

Build Docker image local:

```powershell
docker build -t gateway:local services/gateway
docker build -t auth-service:local services/auth-service
docker build -t course-service:local services/course-service
```

## Deploy thủ công để kiểm tra trên k3s

Trên EC2 master, nếu cần kiểm thử không qua GitHub Actions:

```bash
sudo kubectl apply -f k8s/microservices/namespace.yaml

sudo kubectl create secret generic db-app-secret \
  -n microservices \
  --from-literal=POSTGRES_DB=sagelms \
  --from-literal=POSTGRES_USER=sagelms \
  --from-literal=POSTGRES_PASSWORD='<db-password>' \
  --from-literal=DB_NAME=sagelms \
  --from-literal=DB_USER=sagelms \
  --from-literal=DB_PASSWORD='<db-password>'

sudo kubectl create secret generic app-shared-secret \
  -n microservices \
  --from-literal=JWT_SECRET='<jwt-secret>' \
  --from-literal=GATEWAY_SHARED_SECRET='<gateway-shared-secret>' \
  --from-literal=INTERNAL_API_SECRET='<internal-api-secret>'

sudo kubectl apply -f k8s/microservices/postgres-deployment.yaml
sudo kubectl apply -f k8s/microservices/postgres-service.yaml
sudo kubectl rollout status deployment/postgres -n microservices
```

Khi deploy thủ công, thay các placeholder image trong deployment bằng image thật đã có trên registry:

```bash
export GATEWAY_IMAGE=ghcr.io/<owner>/<repo>/gateway:<tag>
export AUTH_IMAGE=ghcr.io/<owner>/<repo>/auth-service:<tag>
export COURSE_IMAGE=ghcr.io/<owner>/<repo>/course-service:<tag>

sudo kubectl apply -f k8s/microservices/auth-configmap.yaml
sed "s#AUTH_IMAGE_PLACEHOLDER#${AUTH_IMAGE}#g" k8s/microservices/auth-deployment.yaml | sudo kubectl apply -f -
sudo kubectl apply -f k8s/microservices/auth-service.yaml

sudo kubectl apply -f k8s/microservices/course-configmap.yaml
sed "s#COURSE_IMAGE_PLACEHOLDER#${COURSE_IMAGE}#g" k8s/microservices/course-deployment.yaml | sudo kubectl apply -f -
sudo kubectl apply -f k8s/microservices/course-service.yaml

sudo kubectl apply -f k8s/microservices/gateway-configmap.yaml
sed "s#GATEWAY_IMAGE_PLACEHOLDER#${GATEWAY_IMAGE}#g" k8s/microservices/gateway-deployment.yaml | sudo kubectl apply -f -
sudo kubectl apply -f k8s/microservices/gateway-service.yaml
```

Nếu trước đó đã deploy `demo-nginx`, xóa để giải phóng NodePort `30080`:

```bash
sudo kubectl delete svc demo-nginx --ignore-not-found
sudo kubectl delete deployment demo-nginx --ignore-not-found
```

## Kiểm tra sau deploy

Trên EC2 master:

```bash
sudo kubectl get nodes -o wide
sudo kubectl get pods -n microservices -o wide
sudo kubectl get svc -n microservices
sudo kubectl rollout status deployment/auth-service -n microservices
sudo kubectl rollout status deployment/course-service -n microservices
sudo kubectl rollout status deployment/gateway -n microservices
```

Từ máy local hoặc EC2:

```bash
curl http://<AlbDnsName>/actuator/health
```

Kết quả mong đợi:

```json
{"status":"UP"}
```

## Test cases

| Test case | Công cụ | Kết quả mong đợi |
| --- | --- | --- |
| Unit test từng service | Maven | Tất cả test pass |
| Build Docker image | Docker | Image build thành công |
| Scan bảo mật image | Trivy | Không có lỗ hổng HIGH/CRITICAL chưa xử lý |
| Scan chất lượng source | SonarQube/SonarCloud | Project được scan nếu có `SONAR_TOKEN` |
| Push image | GHCR | Có image `gateway`, `auth-service`, `course-service` theo commit SHA |
| Deploy Kubernetes | `kubectl apply` | PostgreSQL và 3 service được tạo trong namespace `microservices` |
| Rollout | `kubectl rollout status` | Các deployment rollout thành công |
| Public access | ALB DNS | `/actuator/health` trả `UP` từ gateway |

## Minh chứng cần chụp cho báo cáo

- GitHub Actions workflow `Microservices CI/CD` chạy thành công.
- Log Maven unit test pass cho cả 3 service.
- Log Trivy scan pass cho cả 3 image.
- Log Sonar scan hoặc log skip nếu chưa cấu hình Sonar.
- GHCR có image `gateway`, `auth-service`, `course-service`.
- `kubectl get pods -n microservices -o wide` hiển thị PostgreSQL và 3 service Running.
- `kubectl get svc -n microservices` hiển thị `gateway` có `80:30080/TCP`.
- `curl http://<AlbDnsName>/actuator/health` trả `{"status":"UP"}`.
