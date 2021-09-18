VERSION_DEV = 0.1.0_dev-staging
VERSION_PROD = 0.1.0

commit:
	mix test
	mix format
	mix credo --strict
	git add .
	git cz

commit-release-major:
	mix bump_release major
	mix test
	mix format
	mix credo --strict
	git add .
	git cz

commit-release-minor:
	mix bump_release minor
	mix test
	mix format
	mix credo --strict
	git add .
	git cz

commit-release-patch:
	mix bump_release patch
	mix test
	mix format
	mix credo --strict
	git add .
	git cz

dev-release:
	mix deps.get
	mix compile
	mix release

builddockerprod: 
	docker build --tag discovery .
	docker tag discovery discovery:$(VERSION_PROD)

builddockerdev: 
	docker build --file devDockerfile --tag discovery .
	docker tag discovery discovery:$(VERSION_DEV)

# pushdockerdev: builddockerdev
# 	docker push discovery:$(VERSION_DEV)

# pushdockerprod: builddockerprod
# 	docker push discovery:$(VERSION_PROD)

rundockerprod: 
	docker run --name disovery-$(VERSION_PROD) --publish 6968:6968 --detach --env DISCOVERY_PORT=6968 --env SECRET_KEY_BASE=${SECRET_KEY_BASE} disovery:$(VERSION_PROD)

rundockerdev: builddockerdev
	docker run --name disovery-$(VERSION_DEV) --publish 6966:6966 --detach --env DISCOVERY_PORT=6966 --env SECRET_KEY_BASE=${SECRET_KEY_BASE} disovery:$(VERSION_DEV)