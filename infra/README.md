# infra - ha tang va van hanh

**Chu:** Tan Tai

## Chay moi truong dev bang Docker

Yeu cau: cai Docker Desktop va mo no (cho chu "Engine running").

Chay trong thu muc du an:

    docker compose up -d

Lenh nay dung 2 dich vu:

- postgres:16 o cong 5432 (database)
- stoplight/prism:5 o cong 4010 (mock API theo api/openapi.yaml)

## Kiem tra

    docker compose ps
    curl.exe -H "Authorization: Bearer test" http://localhost:4010/tax/periods
    curl.exe -i http://localhost:4010/tax/periods

Co token thi tra du lieu JSON, khong token thi tra 401.

## Tat

    docker compose down

Them -v de xoa luon du lieu database: docker compose down -v

## Xu ly loi thuong gap

- Docker Desktop chua mo hoac "Engine starting": cho den khi xanh roi chay lai.
- Cong 4010 hoac 5432 dang bi chiem: doi cong bang bien MOCK_PORT trong file .env.
- Mock bi Exited: xem log bang docker compose logs mock. Da co co --no-multiprocess de chay trong Docker.

## Bao mat

Tai khoan va token trong compose chi dung cho may local. Khong dua bi mat, du lieu that hay file .env that len repo.

## Viec con lai

- [x] docker-compose, .env.example
- [ ] Bao ve nhanh main (can quyen admin)
- [ ] Threat model ngan cung Ngoc Thai
- [ ] Them backend vao compose khi co API
