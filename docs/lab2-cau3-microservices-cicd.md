# Lab 2 - Câu 3: CI/CD cho microservices bằng GitHub Actions, Docker, k3s, SonarQube và Trivy

Phần này dùng GitHub Actions như một dịch vụ CI/CD tương tự Jenkins để build, test, kiểm tra chất lượng mã nguồn, kiểm tra bảo mật image và deploy microservice lên cụm k3s đã tạo ở Lab 2 câu 2.

## Vì sao dùng GitHub Actions thay Jenkins?

- Repo đã dùng GitHub làm nơi quản lý source code.
- Không cần dựng và bảo trì Jenkins server riêng.
- GitHub Actions hỗ trợ sẵn workflow CI/CD, GitHub Container Registry, secrets và self-hosted runner.
- Vẫn đáp ứng yêu cầu của đề là dùng Jenkins hoặc một dịch vụ tương tự để tự động hóa build, test và deploy microservices.

Nếu có microservice từ đồ án khác, có thể tái sử dụng khi nó có Dockerfile, test rõ ràng và manifest Kubernetes phù hợp. Trong lab này repo có thêm `catalog-service` tối thiểu để pipeline chạy ổn định và dễ demo.

## Kiến trúc triển khai

```text
GitHub Actions
  -> Unit test
  -> SonarQube/SonarCloud scan
  -> Docker build
  -> Trivy image scan
  -> Push image to GHCR
  -> Self-hosted runner on k3s master
  -> kubectl deploy to k3s
  -> ALB :80 -> worker NodePort :30080 -> catalog-service pods
```

Hạ tầng dùng lại từ câu 2:

- Public EC2 master chạy k3s server/control-plane.
- Hai private EC2 worker chạy k3s agent.
- ALB forward HTTP port `80` vào worker NodePort `30080`.

## Cấu trúc source

```text
apps/catalog-service/
|-- Dockerfile
|-- package.json
|-- src/server.js
`-- test/server.test.js

k8s/microservices/
|-- namespace.yaml
|-- catalog-deployment.yaml
`-- catalog-service.yaml

.github/workflows/microservices-cicd.yml
sonar-project.properties
```

## Kiểm tra app local

```powershell
cd apps/catalog-service
npm ci
npm test
npm start
```

Mở endpoint:

```text
http://localhost:3000/health
http://localhost:3000/api/products
```

Build Docker image local:

```powershell
docker build -t catalog-service:local apps/catalog-service
docker run --rm -p 3000:3000 catalog-service:local
```

## Cài GitHub Actions self-hosted runner trên EC2 master

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

Cài runner thành service:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

Kiểm tra runner đã thấy trong GitHub:

```text
Settings -> Actions -> Runners
```

## GitHub secrets và variables

Workflow luôn cần quyền mặc định của `GITHUB_TOKEN` để push image lên GHCR.

Workflow tự chuyển tên image GHCR sang lowercase vì GitHub repository `NT548-Lab` có chữ hoa, còn GHCR yêu cầu image name dạng lowercase. Image được push theo dạng:

```text
ghcr.io/<owner-lowercase>/<repo-lowercase>/catalog-service:<commit-sha>
```

Kubernetes image pull secret trong workflow dùng `GITHUB_TOKEN` để kéo image ngay sau khi deploy. Cách này đủ cho lab. Nếu muốn vận hành lâu dài với package private, nên tạo PAT có quyền `read:packages` và thay bằng secret riêng như `GHCR_PAT`.

Nếu muốn chạy SonarCloud hoặc SonarQube, cấu hình:

- Secret `SONAR_TOKEN`: token dùng để scan.
- Secret `SONAR_HOST_URL`: URL SonarQube self-hosted, ví dụ `http://<sonarqube-host>:9000`. Nếu dùng SonarCloud có thể bỏ qua.
- Variable `SONAR_ORGANIZATION`: organization key trên SonarCloud.

Nếu chưa cấu hình `SONAR_TOKEN`, workflow sẽ bỏ qua bước Sonar scan và vẫn chạy các bước còn lại.

## Workflow CI/CD

File workflow:

```text
.github/workflows/microservices-cicd.yml
```

Pipeline có 2 job:

1. `build-test-scan`
   - checkout source
   - setup Node.js
   - `npm ci`
   - `npm test`
   - chạy SonarQube/SonarCloud nếu có token
   - build Docker image
   - scan image bằng Trivy
   - push image lên GitHub Container Registry

2. `deploy-k3s`
   - chạy trên `self-hosted` runner ở EC2 master
   - tạo namespace `microservices`
   - tạo GHCR image pull secret
   - apply Kubernetes manifests
   - rollout deployment
   - in pod/service sau deploy

## Deploy thủ công để kiểm tra

Nếu muốn deploy trước khi chạy workflow, trên EC2 master:

```bash
sudo kubectl apply -f k8s/microservices/namespace.yaml
sed "s#IMAGE_PLACEHOLDER#nginx:1.25#g" k8s/microservices/catalog-deployment.yaml | sudo kubectl apply -f -
sudo kubectl apply -f k8s/microservices/catalog-service.yaml
sudo kubectl get pods -n microservices -o wide
sudo kubectl get svc -n microservices
```

Service dùng NodePort `30080`, nên ALB public DNS sẽ truy cập được app:

```bash
curl http://<AlbDnsName>
```

Nếu trước đó đã deploy service test `demo-nginx` ở câu 2, cần xóa để giải phóng NodePort `30080`:

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
sudo kubectl rollout status deployment/catalog-service -n microservices
```

Từ máy local hoặc trên EC2:

```bash
curl http://<AlbDnsName>
curl http://<AlbDnsName>/health
curl http://<AlbDnsName>/api/products
```

## Test cases

| Test case | Công cụ | Kết quả mong đợi |
| --- | --- | --- |
| Unit test microservice | `npm test` | Tất cả test pass |
| Build Docker image | Docker | Image build thành công |
| Scan bảo mật image | Trivy | Không có lỗ hổng HIGH/CRITICAL chưa được xử lý |
| Scan chất lượng source | SonarQube/SonarCloud | Project được scan, không fail quality gate nếu có cấu hình |
| Push image | GHCR | Image `catalog-service:<commit-sha>` được push |
| Deploy Kubernetes | `kubectl apply` | Deployment và Service được tạo |
| Rollout | `kubectl rollout status` | Deployment rollout thành công |
| Public access | ALB DNS | Trả JSON từ `catalog-service` |

## Minh chứng cần chụp cho báo cáo

- GitHub Actions workflow `Microservices CI/CD` chạy thành công.
- Log unit test pass.
- Log Trivy scan pass.
- Log Sonar scan hoặc log skip nếu chưa cấu hình Sonar.
- GHCR có image `catalog-service`.
- `kubectl get pods -n microservices -o wide` hiển thị 2 pod Running.
- `kubectl get svc -n microservices` hiển thị `80:30080/TCP`.
- `curl http://<AlbDnsName>/health` trả JSON `{ "status": "ok" }`.
