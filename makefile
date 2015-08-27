csa_hs: csa.hs makefile
	ghc -o csa_hs -Wall -O3 csa.hs && strip csa_hs

csa_cpp: csa.cc
	g++ $(CPPFLAGS) --std=c++11 -O3 -o csa_cpp csa.cc

csa_go: csa.go
	go build -o csa_go csa.go
