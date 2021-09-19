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

The dashboard is called **Bridge**

[Bridge url](`http://localhost:4000`)

#### Creating an app

- An app is our statefull server
- App's name will be acts as its universal label in Discovery.
- Each app will be having an dedicated url to Discovery.
- Clients use this dedicated endpoint url to get the app's endpoint. (As specified in `Approach` section).

![create-app](doc_assets/create-app.gif?raw=true  "scale app")

#### Deploying and managing an app

- When deploying an app, we have to specify the docker image name (which should be public as of now).
- Bridge shows each app's deployment logs/activites.
- Deployment CRUD operations to app are available as button clicks.

![scale-app](doc_assets/scale-app.gif?raw=true  "create app")

#### Fetching latest server URL from Discovery 

- Client will hit Discovery API, and get the latest server endpoint url.

    ```
    GET - http://localhost:4000/api/get-endpoint?app_name=nightwatch
    
    RESPONSE - 
    {
      "endpoint": "nightwatch.minikube.com/9d00cc18"
    }

    ```


## Demo time

### Things to note
- For demo, we will be using a bare MMO game [client](https://github.com/madclaws/watchers), [server](https://github.com/madclaws/watchex).
- Disclaimer: These projects were not made for spawnfest, we will be just integrating Discovery to these.

### Demo explanation 

#### What is the gameplay?

- Players can traverse the world in four directions.
- They can attack others by clicking `attack` button
- If in any other player is in the radius of 1 grid in any direction, then he/she will die.
- Player respawns after 5s, when he/she dies.

**We recorded a gameplay to demo the discovery's Zero downtime deployment feature. Demo will be explained by timestamp.**

[Discovery demo video](https://drive.google.com/file/d/19xI5wqmnNBNfRr-_9ruqxugOmKouMeq1/view?usp=sharing)

- [00 - 0:15] - Created a new app `watchex` (A phoenix server using websockets)

- [0:16 - 1:56] - Deployed `watchex` with `madclaws/watchex:0.1.5`
    - `madclaws/watchex:0.1.5` build has normal gameplay, as we mentioned before.
    -  Players attacks, dies and respawns.
    - Also both clients are in normal chrome tabs.

- [1:57 - 3:32] - Made a new deployment with `madclaws/watchex:0.1.6`
    - `0.1.6` was our upgrade to the server, that removes the **RESPAWN** feature from the game.
    - Opens 2 new clients in incognito tabs.
    - Players attacks, dies, but they are not respawned. As expected

- [3:33 - 4:12] - Revisits our old clients, which were running in normal chrome tabs
    - But here clients can still respawn, ie they are still connected to old server/build.

- [4:13 - end] -  Reloads old clients (normal chrome tabs).
    - Now when they die, they are not respawned.
    - ie they are connected to the latest deployment.

**Summary: A new upgrade to the system, will not shut the old deployments and will not affect the existing clients. MISSION ACCOMPLISHED**

### Discovery integration / changes for the demo

[server respawn code in 0.1.5 build](https://github.com/madclaws/watchex/blob/4e77bb17a25ac4bf869a5ee570a726981af00f60/lib/watchex/gameplay/entities/player.ex#L160)

[removed respawn code in 0.1.6 build](https://github.com/madclaws/watchex/blob/5a408976d57026cb652fd867057a7d8aa13ba9b8/lib/watchex/gameplay/entities/player.ex#L160)

[Client hitting Discovery for latest server endpoint](https://github.com/madclaws/watchers/blob/12adc573e1bf570fb592b6200bc5126628ee5d08/src/Classes/NetworkManager.ts#L90)


## Roadmap
- Taking out Discovery from minikube and trying with EKS.
- Automatic zombie deployment cleanup.
- More functionalities in Bridge.
## Credits

<div>Discovery logo made by <a href="" title="Nhor Phai">Nhor Phai</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>

