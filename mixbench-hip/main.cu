/**
 * main-omp.cpp: This file is the modified read-only mixbench GPU micro-benchmark suite.
 *
 **/

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <hip/hip_runtime.h>

#define VECTOR_SIZE (8*1024*1024)
#define granularity (8)
#define fusion_degree (4)
#define seed 0.1

__global__ void benchmark_func(float *g_data, const int blockdim, const int compute_iterations) {
	const unsigned int blockSize = blockdim;
	const int stride = blockSize;
	int idx = blockIdx.x*blockSize*granularity + threadIdx.x;
	const int big_stride = gridDim.x*blockSize*granularity;

	float tmps[granularity];
	for(int k=0; k<fusion_degree; k++){
		#pragma unroll
		for(int j=0; j<granularity; j++){
			// Load elements (memory intensive part)
			tmps[j] = g_data[idx+j*stride+k*big_stride];
			// Perform computations (compute intensive part)
			for(int i=0; i<compute_iterations; i++){
				tmps[j] = tmps[j]*tmps[j]+(float)seed;
			}
		}
		// Multiply add reduction
		float sum = 0;
		#pragma unroll
		for(int j=0; j<granularity; j+=2)
			sum += tmps[j]*tmps[j+1];
	  #pragma unroll
		for(int j=0; j<granularity; j++)
			g_data[idx+k*big_stride] = sum;
	}
}


void mixbenchGPU(long size){
	const char *benchtype = "compute with global memory (block strided)";
	printf("Trade-off type:%s\n", benchtype);
	float *cd = (float*) malloc (size*sizeof(float));
  for (int i = 0; i < size; i++) cd[i] = 0;

	const long reduced_grid_size = size/granularity/128;
	const int block_dim = 256;
	const int grid_dim = reduced_grid_size/block_dim;

  float *d_cd;
	hipMalloc((void**)&d_cd, size*sizeof(float));
  hipMemcpy(d_cd, cd,  size*sizeof(float), hipMemcpyHostToDevice);

  for (int compute_iterations = 0; compute_iterations < 2048; compute_iterations++) {
    hipLaunchKernelGGL(benchmark_func, dim3(grid_dim), dim3(block_dim), 0, 0, d_cd, block_dim, compute_iterations);
  }
  hipMemcpy(cd, d_cd, size*sizeof(float), hipMemcpyDeviceToHost);

  // verification
  for (int i = 0; i < size; i++) 
    if (cd[i] != 0) {
      if (fabsf(cd[i] - 0.050807f) > 1e-6f)
        printf("Verification failed at index %d: %f\n", i, cd[i]);
    }

  free(cd);
  hipFree(d_cd);
}


int main(int argc, char* argv[]) {

	unsigned int datasize = VECTOR_SIZE*sizeof(float);

	printf("Buffer size: %dMB\n", datasize/(1024*1024));
	
	mixbenchGPU(VECTOR_SIZE);

	return 0;
}
