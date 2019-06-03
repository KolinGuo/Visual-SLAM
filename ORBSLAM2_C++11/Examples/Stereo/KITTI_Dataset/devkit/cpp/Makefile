all: evaluate_result

evaluate_result: evaluate_result.cpp matrix.cpp matrix.h
	g++ -Wall -O3 -DNDEBUG -o $@ evaluate_result.cpp matrix.cpp

clean:
	rm -rfv evaluate_result
