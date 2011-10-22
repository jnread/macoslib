#tag Class
Class CGImage
Inherits CFType
	#tag Event
		Function ClassID() As UInt32
		  return me.ClassID
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		 Shared Function ClassID() As UInt32
		  #if targetMacOS
		    declare function TypeID lib CarbonLib alias "CGImageGetTypeID" () as UInt32
		    
		    static id as UInt32 = TypeID
		    return id
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ColorSpace() As CGColorSpace
		  if me = nil then
		    return nil
		  end if
		  
		  soft declare function CGImageGetColorSpace lib CarbonLib (image as Ptr) as Ptr
		  
		  return new CGColorSpace(CGImageGetColorSpace(me), false)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(image as CGImage)
		  if image = nil then
		    return
		  end if
		  
		  #if targetMacOS
		    soft declare function CGImageCreateCopy lib CarbonLib (image as Ptr) as Ptr
		    super.Constructor CGImageCreateCopy(image), true
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(image as CGImage, minMaskColor as CGColor, maxMaskColor as CGColor)
		  if image is nil then
		    return
		  end if
		  
		  if minMaskColor is nil then
		    me.Constructor image
		    return
		  end if
		  if maxMaskColor is nil then
		    me.Constructor image
		    return
		  end if
		  
		  #if targetMacOS
		    soft declare function CGImageCreateWithMaskingColors lib CarbonLib (image as Ptr, components as Ptr) as Ptr
		    
		    dim minComponents() as Double = minMaskColor.Components
		    dim maxComponents() as Double = maxMaskColor.Components
		    if UBound(minComponents) <> UBound(maxComponents) then
		      return
		    end if
		    
		    const sizeOfSingle = 4
		    dim components as new MemoryBlock(2*(1 + UBound(minComponents))*sizeOfSingle)
		    dim offset as Integer = 0
		    for index as Integer = 0 to UBound(minComponents)
		      components.SingleValue(offset) = minComponents(index)
		      offset = offset + 4
		      components.SingleValue(offset) = maxComponents(index)
		      offset = offset + 4
		    next
		    
		    super.Constructor CGImageCreateWithMaskingColors(image, components), true
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(image as CGImage, colorspace as CGColorSpace)
		  if image = nil then
		    return
		  end if
		  
		  if colorspace is nil then
		    me.Constructor image
		    return
		  end if
		  
		  #if targetMacOS
		    soft declare function CGImageCreateCopyWithColorSpace lib CarbonLib (image as Ptr, colorspace as Ptr) as Ptr
		    
		    super.Constructor CGImageCreateCopyWithColorSpace(image, colorspace), true
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(image as CGImage, mask as CGImage)
		  if image is nil then
		    return
		  end if
		  
		  if mask is nil then
		    me.Constructor image
		    return
		  end if
		  
		  #if targetMacOS
		    soft declare function CGImageCreateWithMask lib CarbonLib (image as Ptr, mask as Ptr) as Ptr
		    super.Constructor CGImageCreateWithMask(image, mask), true
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CreateMask() As CGImage
		  if me = nil then
		    return nil
		  end if
		  
		  
		  #if targetMacOS
		    dim c as new CGBitmapContext(me.Width, me.Height, CGColorSpace.GenericGray)
		    c.DrawImage me, CGRectMake(0, 0, me.Width, me.Height)
		    dim image as CGImage = c.CopyImage
		    
		    soft declare function CGImageMaskCreate lib CarbonLib (width as Integer, height as Integer, bitsPerComponent as Integer, bitsPerPixel as Integer, bytesPerRow as Integer, provider as Ptr, decode as Ptr, shouldInterpolate as Integer) as Ptr
		    
		    return new CGImage(CGImageMaskCreate(image.Width, image.Height,image.BitsPerComponent, image.BitsPerPixel, image.BytesPerRow, image.DataProvider, nil, 0), true)
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DataProvider() As CGDataProvider
		  if me = nil then
		    return nil
		  end if
		  
		  #if targetMacOS
		    soft declare function CGImageGetDataProvider lib CarbonLib (image as Ptr) as Ptr
		    
		    return new CGDataProvider(CGImageGetDataProvider(me), false)
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MakeNSImage() As NSImage
		  #if targetMacOS
		    
		    declare function alloc lib CocoaLib selector "alloc" (class_id as Ptr) as Ptr
		    declare function initWithCGImage lib CocoaLib selector "initWithCGImage:size:" (obj_id as Ptr, image as Ptr, size as Cocoa.NSSize) as Ptr
		    
		    //we pass zeroSize to create an NSImage of the same size as the CGImage.
		    dim zeroSize as Cocoa.NSSize
		    dim p as Ptr = initWithCGImage(alloc(Cocoa.NSClassFromString("NSImage")), self, zeroSize)
		    return new NSImage(p, NSObject.hasOwnership)
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MakePicture() As Picture
		  dim p as new Picture(self.Width, self.Height, 32)
		  dim context as new CGContextGraphicsPort(p.Graphics)
		  context.DrawImage(self, CGRectMake(0.0, 0.0, p.Width, p.Height))
		  return p
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function NewCGImage(p as Picture) As CGImage
		  if p is nil then
		    return nil
		  end if
		  
		  dim g as Graphics = p.Graphics
		  
		  if g is nil then //copy into new picture
		    dim pCopy as new Picture(p.Width, p.Height, 32)
		    dim gCopy as Graphics = pCopy.Graphics
		    if gCopy is nil then
		      return nil
		    end if
		    gCopy.DrawPicture p, 0, 0
		    p = pCopy
		    g = gCopy
		  end if
		  if g is nil then //I give up
		    return nil
		  end if
		  
		  soft declare function QDBeginCGContext lib CarbonLib (port as Ptr, ByRef contextPtr as Ptr) as Integer
		  soft declare function CGBitmapContextCreateImage lib CarbonLib (c as Ptr) as Ptr
		  soft declare function QDEndCGContext lib CarbonLib (port as Ptr, ByRef context as Ptr) as Integer
		  
		  
		  #if targetCarbon
		    dim gworldData as Ptr = Ptr(g.Handle(Graphics.HandleTypeCGrafPtr))
		    if gworldData = nil then
		      return nil
		    end if
		    
		    dim c as Ptr
		    dim OSError as Integer = QDBeginCGContext(gworldData, c)
		    if OSError <> 0 or c = nil then
		      return nil
		    end if
		    dim image as new CGImage(CGBitmapContextCreateImage(c), CFType.hasOwnership)
		    OSError = QDEndCGContext(gworldData, c)
		    
		    return image
		  #endif
		  
		  #if targetCocoa
		    dim context as Ptr = Ptr(g.Handle(Graphics.HandleTypeCGContextRef))
		    dim image as new CGImage(CGBitmapContextCreateImage(context), CFType.hasOwnership)
		    return image
		  #endif
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Transform(transformType as Integer) As CGImage
		  // Note: Available in Mac OS X v10.4 and later
		  
		  #if targetMacOS
		    soft declare function HICreateTransformedCGImage lib CarbonLib (inImage as Ptr, inTransform as UInt32, ByRef outImage as Ptr) as Integer
		    
		    dim p as Ptr
		    dim OSStatus as Integer = HICreateTransformedCGImage(me, transformType, p)
		    if OSStatus = noErr then
		      const hasOwnership = true
		      return new CGImage(p, hasOwnership)
		    else
		      return nil
		    end if
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TransformDisabled() As CGImage
		  // Note: Available in Mac OS X v10.4 and later
		  
		  const kHITransformDisabled = &h01
		  return me.Transform(kHITransformDisabled)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TransformNone() As CGImage
		  // Note: Available in Mac OS X v10.4 and later
		  
		  const kHITransformNone = &h00
		  return me.Transform(kHITransformNone)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TransformSelected() As CGImage
		  // Note: Available in Mac OS X v10.4 and later
		  
		  const kHITransformSelected = &h4000
		  return me.Transform(kHITransformSelected)
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  if me = nil then
			    return 0
			  end if
			  
			  #if targetMacOS
			    soft declare function CGImageGetBitsPerComponent lib CarbonLib (image as Ptr) as Integer
			    
			    return CGImageGetBitsPerComponent(me)
			  #endif
			End Get
		#tag EndGetter
		BitsPerComponent As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  if me = nil then
			    return 0
			  end if
			  
			  #if targetMacOS
			    soft declare function CGImageGetBitsPerPixel lib CarbonLib (image as Ptr) as Integer
			    
			    return CGImageGetBitsPerPixel(me)
			  #endif
			End Get
		#tag EndGetter
		BitsPerPixel As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  if me = nil then
			    return 0
			  end if
			  
			  #if targetMacOS
			    soft declare function CGImageGetBytesPerRow lib CarbonLib (image as Ptr) as Integer
			    
			    return CGImageGetBytesPerRow(me)
			  #endif
			End Get
		#tag EndGetter
		BytesPerRow As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  if me = nil then
			    return 0
			  end if
			  
			  #if targetMacOS
			    soft declare function CGImageGetHeight lib CarbonLib (image as Ptr) as Integer
			    
			    return CGImageGetHeight(me)
			  #endif
			End Get
		#tag EndGetter
		Height As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  if me = nil then
			    return false
			  end if
			  
			  #if targetMacOS
			    soft declare function CGImageIsMask lib CarbonLib (image as Ptr) as Boolean
			    
			    return CGImageIsMask(me)
			  #endif
			End Get
		#tag EndGetter
		IsMask As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  if me = nil then
			    return 0
			  end if
			  
			  #if targetMacOS
			    soft declare function CGImageGetWidth lib CarbonLib (image as Ptr) as Integer
			    
			    return CGImageGetWidth(me)
			  #endif
			End Get
		#tag EndGetter
		Width As Integer
	#tag EndComputedProperty


	#tag Constant, Name = AlphaFirst, Type = Double, Dynamic = False, Default = \"4", Scope = Public
	#tag EndConstant

	#tag Constant, Name = AlphaLast, Type = Double, Dynamic = False, Default = \"3", Scope = Public
	#tag EndConstant

	#tag Constant, Name = AlphaNoneSkipFirst, Type = Double, Dynamic = False, Default = \"6", Scope = Public
	#tag EndConstant

	#tag Constant, Name = AlphaNoneSkipLast, Type = Double, Dynamic = False, Default = \"5", Scope = Public
	#tag EndConstant

	#tag Constant, Name = AlphaPremultipliedFirst, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = AlphaPremultipliedLast, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="BitsPerComponent"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="BitsPerPixel"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="BytesPerRow"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Description"
			Group="Behavior"
			Type="String"
			InheritedFrom="CFType"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Height"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsMask"
			Group="Behavior"
			InitialValue="0"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Width"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
