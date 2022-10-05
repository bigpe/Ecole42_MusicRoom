all: clean run

run:
	docker compose up -d

clean-compose:
	docker compose kill
	docker compose rm --force

clean-network:
	docker network rm ecole42_musicroom_default

clean-images:
	docker rmi nginx:alpine postgres:alpine redis

clean: clean-compose clean-network clean-images
