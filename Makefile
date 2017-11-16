build:
	@docker-compose build gem

dev:
	@docker-compose run --rm gem

down:
	@docker-compose down --remove-orphans --volumes
