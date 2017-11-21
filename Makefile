build:
	@docker-compose build gem

dev:
	@docker-compose run --rm gem 'bash'

down:
	@docker-compose down --remove-orphans --volumes

test:
	@docker-compose run --rm gem 'rspec'
