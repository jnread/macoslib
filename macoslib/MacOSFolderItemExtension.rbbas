#tag Module
Protected Module MacOSFolderItemExtension
	#tag Method, Flags = &h21
		Private Function AreNamesEqual(name1 as String, name2 as String, casesensitive as Boolean) As Boolean
		  //this code compares file names following Apple Technical Note TN1150.  It assumes that names are normalized according to
		  //Unicode Normalization Form D.
		  
		  #if targetMacOS
		    dim uname1 as String = ConvertEncoding(name1, Encodings.UTF16)
		    dim uname2 as String = ConvertEncoding(name2, Encodings.UTF16)
		    
		    if casesensitive then
		      return StrComp(uname1, uname2, 0) = 0
		    else
		      declare function UCCompareTextNoLocale lib CarbonLib (options as UInt32, text1Ptr as CString, text1Length as Integer, text2Ptr as CString, text2Length as Integer, ByRef equivalent as Boolean, order as Ptr) as Integer
		      const kUCCollateTypeHFSExtended = &h1000000
		      dim options as UInt32 = kUCCollateTypeHFSExtended
		      dim equivalent as Boolean
		      dim err as Integer = UCCompareTextNoLocale(options, uname1, Len(uname1), uname2, Len(uname2), equivalent, nil)
		      #pragma unused err
		      return equivalent
		    end If
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DeviceName(extends f as FolderItem) As String
		  //DeviceName returns the BSD name of the volume containing f as found in the directory /dev.  Only local volumes have such names.
		  
		  if f Is nil then
		    return ""
		  end if
		  
		  #if TargetMacOS
		    soft declare function PBHGetVolParmsSync lib CarbonLib (ByRef paramBlock as HIOParam) as Short
		    
		    dim paramBlock as HIOParam
		    paramBlock.ioVRefNum = f.MacVRefNum
		    //the following line is a trick to work around the inability to assign a pointer to a structure
		    //to a field of type Ptr.
		    dim infoBuffer as new MemoryBlock(GetVolParmsInfoBuffer.Size)
		    paramBlock.ioBuffer = infoBuffer
		    paramBlock.ioReqCount = infoBuffer.Size
		    
		    dim OSError as Integer = PBHGetVolParmsSync(paramBlock)
		    if OSError <> 0 then
		      return ""
		    end if
		    
		    dim infoBufferPtr as GetVolParmsInfoBuffer = paramBlock.ioBuffer.GetVolParmsInfoBuffer(0)
		    if infoBufferPtr.vMServerAddr = 0 then
		      if infoBufferPtr.vMDeviceID <> nil then
		        dim s as MemoryBlock = infoBufferPtr.vMDeviceID
		        dim BSDName as String = s.CString(0)
		        return DefineEncoding(BSDName, Encodings.SystemDefault)
		      else
		        return ""
		      end if
		    else
		      // vMServerAddr <> 0 means it's a network device, which apparently won't have a BSD name.
		      return ""
		    end if
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Equals(extends f as FolderItem, g as FolderItem) As Boolean
		  //f cannot be nil; if it were, the framework would raise a NilObjectException before this method was invoked.
		  #if targetMacOS
		    if g <> nil then
		      if f.Exists then
		        if g.Exists then
		          soft declare function FSCompareFSRefs lib CarbonLib (ref1 as Ptr, ref2 as Ptr) as Int16
		          #if RBVersion >= 2010.05
		            dim fRef as MemoryBlock = f.MacFSRef
		            dim gRef as MemoryBlock = g.MacFSRef
		          #else
		            dim fRef as MemoryBlock = f.FSRef
		            dim gRef as MemoryBlock = g.FSRef
		          #endif
		          return FSCompareFSRefs(fRef, gRef) = noErr
		        else
		          return false
		        end if
		      else
		        if g.Exists then
		          return false
		        else
		          //compare parents + names.
		          dim f_parent as FolderItem = f.Parent
		          dim g_parent as FolderItem = g.Parent
		          if f_parent <> nil and g_parent <> nil then
		            return AreNamesEqual(f.Name, g.Name, IsVolumeCaseSensitive(f)) and f_parent.Equals(g_parent)
		          else
		            //in general, f.Parent = nil only if f is the root FolderItem, in which case f.Exists would be true.  But, thanks to BSD under the hood, one must always expect permissions issues.
		            //So in this case, we give up.
		            return false
		          end if
		        end if
		      end if
		    else
		      return false
		    end if
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function FreeSpace(extends theVolume as FolderItem) As UInt64
		  #if targetMacOS
		    
		    soft declare function FSGetVolumeInfo lib CarbonLib (volume as Int16, volumeIndex as Integer, actualVolume as Ptr, whichInfo as UInt32, ByRef info as FSVolumeInfo, volumeName as Ptr, rootDirectory as Ptr) as Int16
		    
		    dim theInfo as FSVolumeInfo
		    dim OSErr as Int16 = FSGetVolumeInfo(theVolume.MacVRefNum, 0, nil, FileManager.kFSVolInfoSizes, theInfo, nil, nil)
		    if OSErr <> noErr then
		      break
		      return 0
		    end if
		    
		    return theInfo.freeBytes
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function inode(extends f as FolderItem) As UInt32
		  #if targetMacOS
		    dim ref as FSRef = FileManager.GetFSRefFromFolderItem(f)
		    
		    soft declare function FSGetCatalogInfo lib CarbonLib (ref as Ptr, whichInfo as Uint32, _
		    ByRef catalogInfo as FSCatalogInfo, outName as Ptr, fsSpec as Ptr,  parentRef as Ptr) as Int16
		    
		    dim cataloginfo as FileManager.FSCatalogInfo
		    dim err as Int16 = FSGetCatalogInfo(ref, FileManager.kFSCatInfoNodeID, cataloginfo, nil, nil, nil)
		    #pragma unused err
		    
		    return cataloginfo.nodeid
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IOMediaClass(extends f as FolderItem) As String
		  //This function, using code from the Apple sample project VolumeToBSDNode, looks up the class name of an IOObject using IO Kit.  It will return
		  //IOCDMedia for a CD, IODVDMedia for a DVD, and IOMedia for anything else.  Thus this function will tell you whether a local volume is a CD or DVD.
		  //It returns "' for network volumes or if an error occurs.
		  
		  
		  #if targetMacOS
		    const IOKitFramework = "IOKit.framework"
		    const kIOMasterPortDefault = nil //see IOKitLib.h
		    const IO_OBJECT_NULL = nil
		    const kIOMediaClass = "IOMedia"
		    const kIOServicePlane = "IOService"
		    const kIORegistryIterateRecursively = &h00000001
		    const kIORegistryIterateParents = &h00000002
		    const kIOCDMediaClass = "IOCDMedia"
		    const kIOMediaWholeKey = "Whole"
		    const kCFAllocatorDefault = nil
		    
		    soft declare function IOBSDNameMatching lib IOKitFramework (masterPort as Ptr, options as Integer, bsdName as CString) as Ptr
		    soft declare function IOServiceGetMatchingService lib IOKitFramework (masterPort as Ptr, matching as Ptr) as Ptr
		    // /usr/include/device/device_types.h:typedef    char            io_name_t[128];
		    
		    soft declare function IORegistryEntryCreateIterator lib IOKitFramework (entry as Ptr, plane as CString, options as Integer, ByRef iterator as Ptr) as Integer
		    soft declare function IOObjectConformsTo lib IOKitFramework (obj as Ptr, className as CString) as Boolean
		    soft declare function IORegistryEntryCreateCFProperty lib IOKitFramework (entry as Ptr, key as CFStringRef, allocator as Ptr, options as Integer) as Ptr
		    soft declare function IOObjectGetClass lib IOKitFramework (obj as Ptr, className as Ptr) as Integer
		    soft declare function IOObjectRetain lib IOKitFramework (obj as Ptr) as Integer
		    soft declare function IOObjectRelease lib IOKitFramework (obj as Ptr) as Integer
		    
		    //the documentation for this function suggests that we don't need to free dPtr (it's a CFMutableDictionaryRef) because we pass it to IOServiceGetMatchingService
		    //which consumes a reference.  Some testing with CFGetRetainCount confirms this.
		    dim dPtr as Ptr = IOBSDNameMatching(kIOMasterPortDefault, 0, f.DeviceName)
		    if dPtr = nil then
		      return ""
		    end if
		    
		    dim service as Ptr = IOServiceGetMatchingService(kIOMasterPortDefault, dPtr)
		    if service = IO_OBJECT_NULL then
		      return ""
		    end if
		    dim iterator as Ptr
		    dim iteratorErr as Integer = IORegistryEntryCreateIterator(service, kIOServicePlane, kIORegistryIterateRecursively or kIORegistryIterateParents, iterator)
		    if iteratorErr <> 0 or iterator = nil then
		      return ""
		    end if
		    
		    dim retainErr as Integer = IOObjectRetain(service)
		    dim className as new MemoryBlock(128)
		    do
		      if IOObjectConformsTo(service, kIOMediaClass) then
		        dim p as Ptr = IORegistryEntryCreateCFProperty(service, kIOMediaWholeKey, kCFAllocatorDefault, 0)
		        soft declare function CFBooleanGetValue lib CarbonLib (cf as Ptr) as Boolean
		        dim isWholeMedia as Boolean = p <> nil and CFBooleanGetValue(p)
		        if isWholeMedia then
		          dim getClassError as Integer = IOObjectGetClass(service, className)
		          #pragma unused getClassError
		          exit
		        else
		          //another iteration
		        end if
		      else
		        //another iteration
		      end if
		      
		      
		      soft declare function IOIteratorNext lib IOKitFramework (iterator as Ptr) as Ptr
		      dim releaseError as Integer = IOObjectRelease(service)
		      #pragma unused releaseError
		      service = IOIteratorNext(iterator)
		      if service = nil then
		        exit
		      end if
		    loop
		    
		    iteratorErr = IOObjectRelease(iterator)
		    dim releaseError as Integer = IOObjectRelease(service)
		    
		    return DefineEncoding(className.CString(0), Encodings.SystemDefault)
		    
		    // Keep the compiler from complaining
		    #pragma unused retainErr
		    #pragma unused releaseError
		  #endif
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsBundle(f as FolderItem) As Boolean
		  if f is nil then
		    return false
		  end if
		  
		  #if TargetMacOS
		    soft declare function LSCopyItemInfoForRef lib CarbonLib (fsRef as Ptr, inWhichInfo as Integer, ByRef outItemInfo as LSItemInfoRecord) as Integer
		    
		    const kLSRequestBasicFlagsOnly = &h00000004
		    const kLSItemInfoIsPackage = &h00000002
		    
		    dim theRef as FSRef = FileManager.GetFSRefFromFolderItem(f)
		    dim itemInfo as LSItemInfoRecord
		    dim OSError as Integer = LSCopyItemInfoForRef(theRef, kLSRequestBasicFlagsOnly, itemInfo)
		    if OSError <> 0 then
		      break
		    end if
		    return (itemInfo.Flags and kLSItemInfoIsPackage) = kLSItemInfoIsPackage
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsNetworkVolume(f as FolderItem) As Boolean
		  if f Is nil then
		    return false
		  end if
		  
		  #if TargetMacOS
		    soft declare function PBHGetVolParmsSync lib CarbonLib (ByRef paramBlock as HIOParam) as Short
		    
		    dim paramBlock as HIOParam
		    paramBlock.ioVRefNum = f.MacVRefNum
		    //the following line is a trick to work around the inability to assign a pointer to a structure
		    //to a field of type Ptr.
		    dim infoBuffer as new MemoryBlock(GetVolParmsInfoBuffer.Size)
		    paramBlock.ioBuffer = infoBuffer
		    paramBlock.ioReqCount = infoBuffer.Size
		    
		    dim OSError as Integer = PBHGetVolParmsSync(paramBlock)
		    if OSError <> 0 then
		      return false
		    end if
		    return (infoBuffer.Long(10) <> 0)
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MoveToTrash(extends f as FolderItem)
		  #if targetMacOS
		    dim source as FSRef = FileManager.GetFSRefFromFolderItem(f)
		    
		    soft declare function FSMoveObjectToTrashSync lib CarbonLib (fsRef as Ptr, target as Ptr, options as UInt32) as Integer
		    
		    dim OSError as Integer = FSMoveObjectToTrashSync(source, nil, 0)
		    
		    // Keep the compiler from complaining
		    #pragma unused OSError
		  #endif
		  
		  
		End Sub
	#tag EndMethod


	#tag Note, Name = About
		This is part of the open source "MacOSLib"
		
		Original sources are located here:  http://code.google.com/p/macoslib
	#tag EndNote


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
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
	#tag EndViewBehavior
End Module
#tag EndModule
