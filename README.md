![logo](doc_assets/discovery-logo.png?raw=true  "title")

# Discovery

**Platform for hosting realtime, stateful servers with zero downtime deployment and horizontal scaling on Kubernetes**

![Discovery CI-CD](https://github.com/spawnfest/Discovery/actions/workflows/discovery.yml/badge.svg)

## Table of Contents

1. [Why?](#why)
2. [Features](#features)
3. [Approach](#approach)
4. [Running Discovery](#running-discovery)
    - [Prerequisites](#prerequisites)
    - [Setup Tips](#setup-tips)
    - [Running Discovery server](#running-discovery-server)
    - [Using dashboard](#using-dashboard)
5. [Demo time](#demo-time)
6. [Roadmap](#roadmap)

## Why?

The primary goals of **Discovery** is to solve two very important problems during the deployment of real-time state-full servers.

- Zero-downtime deployment.
- Horizontal scaling.

These are non-trivial because,
- Server's communications are state-full (uses websocket mostly instead of https REST model)
- Most often states are stored in-memory (as states fetching, manipulation and relaying needs to be done very fast and they are ephemeral). 
- Due to above properties, doing a rolling deployment or scaling horizontally like normal stateless apps is not feasible in k8s. 
- Rolling deployment deletes the old pods and load balancers can route connections to incorrect pods.

**Discovery aims to solve this by acting as a platform over the Kubernetes.**

Examples of real-time state-full servers are **game-servers**, **chat servers** etc..

### Why not store state in Postgresql/Redis?

- Statefull servers like game-server's states can't be mapped to a relational database.
- As mentioned above states are to be fetched, manipulated continuously, which is no an use-case of Postgres.
- Even though state can be stored in Redis as its a KV db. We can't allow shutting down
servers while users are connected due to reasons below,
    - reconnection spike will be huge.
    - Servers of these type are most often `alive` , that means processes will be running
      some code always (ex consider game timers/background simulations) even without
      user intervention. 
    - Deleting/shutting servers has adverse effect on client-side too.

Added advantages of building over Kubernetes,

- We can distribute our servers in different regions, this will benefit in reducing the latency as realtime servers are latency prone.
- We can continue use stateful methods, but can also use persistence storage like Postgresql, when in need, like user login etc..
- Leveraging the open-source, almost industry standard deployment solution.

## Features

- Zero downtime deployment.
- Horizontally scalable.
- Network reconnections always route to correct server.
- Built-in dashboard for deployment operations.
- APIs that can be run from iex repl for deployments.
- Can deploy language agnostic servers.
- Code as the source of truth.

## Approach

**The goal is, there should be never a downtime for the current users, while we update our statefull servers.**

### Client-Server communication with Discovery

![cs](doc_assets/new_cs_communcation_1.png?raw=true  "title")

1. Discovery deployed server_v1 to k8.
2. Client_A and Client_B asks Discovery to get the latest url via https, Discovery returns server_v1's url
3. Client_A and Client_B then directly connects to server_v1 as a websocket connection, all further messages and events are send without discovery, like a normal websocket app.
4. When a state-full session is over, client can repeat from step 2.

### Client-Server communication with Discovery during upgrades

![cs2](doc_assets/new_cs_communcation_2b.png?raw=true  "title")

1. Discovery deployed server_v2 after some time.
2. Client_A and Client_B will be still communicating with server_v1
3. New Client_C and Client_D asks Discovery to get the latest url via https, Discovery returns server_v2's url
4. Client_C and Client_D then directly connects to server_v2 as a websocket connection, all further messages and events are send without discovery, like a normal websocket app.
5. When a state-full session is over, clients can repeat from step 2.

- Here we can see, for **new upgrades we don't shut older deployments**.
- Eventually there will be no connections in server_v1 and then Discovery gracefully shuts it.
- All new statefull sessions will be connecting to new deployment.


## Running Discovery

### prerequisites

- Linux environment.
- [kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
- Docker
- [minikube](https://minikube.sigs.k8s.io/docs/start/)

### Setup Tips

- `docker login`
- `minikube start --driver=docker` (starting minikube)
- `kubectl config use-context minikube` (set kubectl to use minikube cluster)
- `minikube addons enable ingress` (Setting up ingress-nginx)

### Running Discovery server

- clone the repo
- `mix setup`
- `iex -S mix phx.server`

### Using dashboard

The dashboard/platform is called Bridge

[Bridge url](`http://localhost:4000`)

#### Creating an app

- An app is our statefull server
- App's name will be acts as its universal label in Discovery.
- Each app will be having an dedicated url to Discovery.
- Clients use this dedicated endpoint url to get the app's endpoint. (As specified in `Approach` section).

#### Deploying and managing an app

- When deploying an app, we have to specify the docker image name (which should be public as of now).
- Bridge shows each app's deployment logs/activites.
- Deployment CRUD operations to app are available as button clicks.

## Demo time

### Things to note
- For demo, we will be using a bare MMO game [client](https://github.com/madclaws/watchers), [server](https://github.com/madclaws/watchex).
- Disclaimer: These projects were not made for spawnfest, we will be just integrating Discovery to these.
 



## Roadmap
- Taking out Discovery from minikube and trying with EKS.
- Automatic zombie deployment cleanup.
- More functionalities in Bridge.
## Credits

<div>Discovery logo made by <a href="" title="Nhor Phai">Nhor Phai</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>