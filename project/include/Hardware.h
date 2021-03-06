#ifndef NME_HARDWARE_H
#define NME_HARDWARE_H

#include "Graphics.h"

namespace nme
{

void ResetHardwareContext();

typedef QuickVec<UserPoint>   Vertices;

enum PrimType { ptTriangleFan, ptTriangleStrip, ptTriangles, ptLineStrip, ptPoints, ptLines };

enum
{
   DRAW_HAS_COLOUR      = 0x00000001,
   DRAW_HAS_NORMAL      = 0x00000002,
   DRAW_HAS_PERSPECTIVE = 0x00000004,
   DRAW_RADIAL          = 0x00000008,

   DRAW_HAS_TEX         = 0x00000010,
   DRAW_BMP_REPEAT      = 0x00000020,
   DRAW_BMP_SMOOTH      = 0x00000040,
};




struct DrawElement
{
   uint8        mFlags;
   uint8        mPrimType;
   uint8        mBlendMode;
   uint8        mScaleMode;
   short        mRadialPos;

   uint8        mStride;
   int          mCount;

   int          mVertexOffset;
   int          mTexOffset;
   int          mColourOffset;
   int          mNormalOffset;

   uint32       mColour;
   Surface      *mSurface;

   // For  ptLineStrip/ptLines
   float    mWidth;

};

typedef QuickVec<DrawElement> DrawElements;

class HardwareData
{
public:
   HardwareData();
   ~HardwareData();

   void            releaseVbo();
   float           scaleOf(const RenderState &inState) const;
   bool            isScaleOk(const RenderState &inState) const;
   void            clear();

   DrawElements    mElements;
   QuickVec<uint8> mArray;
   float           mMinScale;
   float           mMaxScale;

   mutable HardwareContext *mVboOwner;
   mutable int             mRendersWithoutVbo;
   mutable unsigned int    mVertexBo;
   mutable int             mContextId;
};


void ConvertOutlineToTriangles(Vertices &ioOutline,const QuickVec<int> &inSubPolys);

class HardwareContext : public Object
{
public:
   static HardwareContext *current;
   static HardwareContext *CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders);
   static HardwareContext *CreateDX11(void *inDevice, void *inContext);

   // Could be common to multiple implementations...
   virtual bool Hits(const RenderState &inState, const HardwareData &inData );

   virtual void SetWindowSize(int inWidth,int inHeight)=0;
   virtual void SetQuality(StageQuality inQuality)=0;
   virtual void BeginRender(const Rect &inRect,bool inForHitTest)=0;
   virtual void EndRender()=0;
   virtual void SetViewport(const Rect &inRect)=0;
   virtual void Clear(uint32 inColour,const Rect *inRect=0) = 0;
   virtual void Flip() = 0;

   virtual int Width() const = 0;
   virtual int Height() const = 0;


   virtual class Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags)=0;
   virtual void Render(const RenderState &inState, const HardwareData &inData )=0;
   virtual void BeginBitmapRender(Surface *inSurface,uint32 inTint=0,bool inRepeat=true,bool inSmooth=true)=0;
   virtual void RenderBitmap(const Rect &inSrc, int inX, int inY)=0;
   virtual void EndBitmapRender()=0;

   virtual void DestroyNativeTexture(void *inNativeTexture)=0;
   virtual void DestroyVbo(unsigned int inVbo)=0;
};

extern HardwareContext *gDirectRenderContext;

void BuildHardwareJob(const class GraphicsJob &inJob,const GraphicsPath &inPath,
                      HardwareData &ioData, HardwareContext &inHardware,const RenderState &inState);


} // end namespace nme

#endif
