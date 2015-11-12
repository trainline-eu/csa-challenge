csa_hs: csa.hs makefile
	ghc -o csa_hs -Wall -O3 csa.hs && strip csa_hs

csa_cpp: csa.cc
	g++ $(CPPFLAGS) --std=c++11 -O3 -o csa_cpp csa.cc

csa_go: csa.go
	go build -o csa_go csa.go

csa_c: csa.c
	clang -Ofast -o csa_c csa.c

csa_pascal: csa.pas
	fpc csa.pas

csa_swift: csa.swift
	xcrun --sdk macosx swiftc -O -o csa_swift csa.swift
