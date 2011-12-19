#tag Class
Protected Class Process
	#tag Method, Flags = &h0
		Function BundleLocation() As FolderItem
		  //Retrieves the file system location of the application bundle (or executable file) associated with a process.
		  
		  #if targetMacOS
		    soft declare function GetProcessBundleLocation lib CarbonLib (ByRef PSN as ProcessSerialNumber, location as Ptr) as Integer
		    
		    dim theFile as new FSRef
		    dim OSError as Integer = GetProcessBundleLocation(psn, theFile)
		    if OSError = 0 then
		      return FileManager.GetFolderItemFromFSRef(theFile)
		    else
		      return nil
		    end if
		  #endif
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function CurrentProcess() As Process
		  #if targetMacOS
		    soft declare function GetCurrentProcess lib CarbonLib (ByRef psn as ProcessSerialNumber) as Int16
		    
		    dim thePSN as ProcessSerialNumber
		    
		    dim OSError as Int16 = GetCurrentProcess(thePSN)
		    if OSError <> 0 then
		      return nil
		    end if
		    
		    dim p as new Process
		    p.psn = thePSN
		    return p
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Equals(p as Process) As Boolean
		  if p is nil then
		    return false
		  end if
		  
		  #if targetMacOS
		    soft declare function SameProcess lib CarbonLib (ByRef PSN1 as ProcessSerialNumber, ByRef PSN2 as ProcessSerialNumber, ByRef result as Boolean) as Int16
		    
		    dim theOtherPSN as ProcessSerialNumber = p.psn
		    dim theResult as Boolean
		    dim OSError as Int16 = SameProcess(psn, theOtherPSN, theResult)
		    return theResult
		    
		    // Keep the compiler from complaining
		    #pragma unused OSError
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function FrontProcess() As Process
		  #if targetMacOS
		    soft declare function GetFrontProcess lib CarbonLib (ByRef PSN as ProcessSerialNumber) as Int16
		    
		    dim thePSN as ProcessSerialNumber
		    dim OSError as Int16 = GetFrontProcess(thePSN)
		    dim p as new Process
		    p.psn = thePSN
		    return p
		    
		    // Keep the compiler from complaining
		    #pragma unused OSError
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Sub FrontProcess(p as Process, frontWindowOnly as Boolean = false)
		  if p is nil then
		    return
		  end if
		  
		  soft declare function SetFrontProcessWithOptions lib CarbonLib (ByRef psn as ProcessSerialNumber, inOptions as UInt32) as Int32
		  
		  dim thePSN as ProcessSerialNumber = p.psn
		  dim OSError as Int32
		  if frontWindowOnly then
		    const kSetFrontProcessFrontWindowOnly = 1
		    OSError = SetFrontProcessWithOptions(thePSN, kSetFrontProcessFrontWindowOnly)
		  else
		    OSError = SetFrontProcessWithOptions(thePSN, 0)
		  end if
		  
		  // Keep the compiler from complaining
		  #pragma unused OSError
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Kill()
		  #if targetMacOS
		    soft declare function KillProcess lib CarbonLib (ByRef inProcess as ProcessSerialNumber) as Int16
		    
		    dim OSError as Int16 = KillProcess(psn)
		    
		    // Keep the compiler from complaining
		    #pragma unused OSError
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NextProcess() As Process
		  #if targetMacOS
		    soft declare function GetNextProcess lib CarbonLib (ByRef PSN as ProcessSerialNumber) as Int16
		    
		    //GetNextProcess modifies the psn parameter, so we copy me.PSN
		    dim ioPSN as ProcessSerialNumber = me.psn
		    dim OSError as Int16 = GetNextProcess(ioPSN)
		    if OSError = 0 then
		      dim p as new Process
		      p.psn = ioPSN
		      return p
		      
		    elseIf OSError = procNotFound then
		      //end of process list
		      return nil
		      
		    else
		      //an error occurred
		      return nil
		    end if
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function ProcessList() As Process()
		  dim theList() as Process
		  
		  dim p as new Process
		  p.psn.LowLongOfPSN = kNoProcess
		  
		  do
		    p = p.NextProcess
		    if p <> nil then
		      theList.Append p
		    else
		      exit
		    end if
		  loop
		  
		  return theList
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  #if targetMacOS
			    soft declare function CopyProcessName lib CarbonLib (ByRef thePSN as ProcessSerialNumber, ByRef name as CFStringRef) as Int32
			    
			    dim theName as CFStringRef
			    dim OSError as Int32 = CopyProcessName(psn, theName)
			    return theName
			    
			    // Keep the compiler from complaining
			    #pragma unused OSError
			  #endif
			  
			End Get
		#tag EndGetter
		Name As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  #if targetMacOS
			    soft declare function  GetProcessPID lib CarbonLib (ByRef psn as ProcessSerialNumber, ByRef pid as Int32) as Integer
			    
			    dim thePID as Int32
			    dim OSError as Integer = GetProcessPID(psn, thePID)
			    if OSError = 0 then
			      return thePID
			    else
			      return 0
			    end if
			  #endif
			End Get
		#tag EndGetter
		PID As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private psn As ProcessSerialNumber
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  #if targetMacOS
			    soft declare function IsProcessVisible lib CarbonLib (ByRef psn as ProcessSerialNumber) as Boolean
			    
			    return IsProcessVisible(psn)
			  #endif
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  #if targetMacOS
			    soft declare function ShowHideProcess lib CarbonLib (ByRef psn as ProcessSerialNumber, visible as Boolean) as Int16
			    
			    dim OSError as Int16 = ShowHideProcess(psn, value)
			    
			    // Keep the compiler from complaining
			    #pragma unused OSError
			  #endif
			End Set
		#tag EndSetter
		Visible As Boolean
	#tag EndComputedProperty


	#tag Constant, Name = kNoProcess, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = procNotFound, Type = Double, Dynamic = False, Default = \"-600", Scope = Private
	#tag EndConstant


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
			Name="PID"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
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
			Name="Visible"
			Group="Behavior"
			InitialValue="0"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
