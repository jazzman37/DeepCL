import numpy as np


cdef class Layer:
    cdef cDeepCL.Layer *thisptr

    def __cinit__(self):
        pass
    cdef set_thisptr(self, cDeepCL.Layer *thisptr):
        self.thisptr = thisptr
    def forward(self):
        self.thisptr.forward()
    def backward(self):
        self.thisptr.backward()
    def needsBackProp(self):
        return self.thisptr.needsBackProp()
    def getBiased( self ):
        return self.thisptr.biased()
    def getOutputCubeSize(self):
        return self.thisptr.getOutputCubeSize()
    def getOutputPlanes(self):
        return self.thisptr.getOutputPlanes()
    def getOutputSize(self):
        return self.thisptr.getOutputSize()
    def getOutput(self):
        # the underlying c++ method returns a pointer
        # to a block of memory that we dont own
        # we should probably copy it I suppose
        cdef float *output = self.thisptr.getOutput()
        cdef int outputNumElements = self.thisptr.getOutputNumElements()
        planes = self.getOutputPlanes()
        size = self.getOutputSize()
        batchSize = outputNumElements // planes // size // size
        outputArray = np.zeros((batchSize, planes, size, size), dtype=np.float32)
        # cdef c_array.array outputArray = array(floatArrayType, [0] * outputNumElements )
        outreshape = outputArray.reshape(-1)
        # outreshape = output
        for i in range(outputNumElements):
            outreshape[i] = output[i]
        return outputArray
    def getWeights(self):
        cdef int weightsSize = self.thisptr.getPersistSize()
        if weightsSize == 0:
            return None

        weightsArray = np.zeros((weightsSize,), dtype=np.float32)
        # cdef c_array.array weightsArray = weightsArray # array(floatArrayType, [0] * weightsSize )
        cdef float[:] weightsArray_view = weightsArray
        self.thisptr.persistToArray( &weightsArray_view[0] )
        return weightsArray
    def setWeights(self, float[:] weights):
        cdef int weightsSize = self.thisptr.getPersistSize()
        assert weightsSize == len(weights)
#        cdef c_array.array weightsArray = array('f', [0] * weightsSize )
        self.thisptr.unpersistFromArray( &weights[0] )

#        int getPersistSize()
#        void persistToArray(float *array)
#        void unpersistFromArray(const float *array)
    #def setWeightsList(self, weightsList):
        #cdef c_array.array weightsArray = array(floatArrayType)
        #weightsArray.fromlist( weightsList )
        #self.setWeights( weightsArray )
    def asString(self):
        cdef const char *res_charstar = self.thisptr.asNewCharStar()
        cdef str res = str(res_charstar.decode('UTF-8'))
        CppRuntimeBoundary.deepcl_deleteCharStar(res_charstar)
        return res
    def getClassName(self):
        return self.thisptr.getClassNameAsCharStar()

cdef class SoftMax(Layer):
    def __cinit__(self):
        pass

    def getBatchSize(self):
        cdef cDeepCL.SoftMaxLayer *cSoftMax = <cDeepCL.SoftMaxLayer *>(self.thisptr)
        cdef int batchSize = cSoftMax.getBatchSize()
        return batchSize        

    def getLabels(self):
        cdef cDeepCL.SoftMaxLayer *cSoftMax = <cDeepCL.SoftMaxLayer *>(self.thisptr)
        cdef int batchSize = cSoftMax.getBatchSize()
        labelsArray = np.zeros((batchSize), dtype=np.int32)
        # cdef c_array.array labelsArray = array(intArrayType, [0] * batchSize)
        cdef int[:] labelsArray_view = labelsArray
        cSoftMax.getLabels(&labelsArray_view[0])
        return labelsArray

