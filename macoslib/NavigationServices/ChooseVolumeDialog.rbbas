#tag Class
Class ChooseVolumeDialog
Inherits NavigationDialog
	#tag Event
		Function CreateDialog(CreationOptions as NavDialogCreationOptions, eventHandler as Ptr, UserData as Ptr) As Ptr
		  #if targetMacOS
		    soft declare function NavCreateChooseVolumeDialog lib CarbonLib (inOptions as Ptr, inEventProc as Ptr, inFilterProc as Ptr, inClientData as Ptr, ByRef outDialog as Ptr) as Integer
		    
		    dim theRef as Ptr
		    dim OSStatus as Integer = NavCreateChooseVolumeDialog(CreationOptions, eventHandler, nil, UserData, theRef)
		    If OSStatus <> 0 then
		      theRef = nil
		      System.Log System.LogLevelError, "NavigationDialog.Show: NavCreateChooseVolumeDialog returned error " + Str(OSStatus) + "."
		    End if
		    return theRef
		    
		  #else
		    #pragma unused CreationOptions
		    #pragma unused eventHandler
		    #pragma unused UserData
		  #endif
		End Function
	#tag EndEvent


	#tag ViewBehavior
		#tag ViewProperty
			Name="ActionButtonLabel"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AddAutoTranslateItems"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AddRecents"
			Group="Behavior"
			InitialValue="true"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AddTranslateItems"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllFilesInPopup"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowInvisibleFiles"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowMultipleFiles"
			Group="Behavior"
			InitialValue="true"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowOpenPackages"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowPreviews"
			Group="Behavior"
			InitialValue="true"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowStationery"
			Group="Behavior"
			InitialValue="true"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AutoTranslate"
			Group="Behavior"
			InitialValue="true"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CancelButtonLabel"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ClientName"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ConfirmReplacement"
			Group="Behavior"
			InitialValue="true"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="NavigationServices"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="NavigationServices"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Message"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="NavigationServices"
		#tag EndViewProperty
		#tag ViewProperty
			Name="NoTypePopup"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="PreserveSaveFileExtension"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ResolveAliases"
			Group="Behavior"
			InitialValue="true"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SaveFileName"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SelectAllReadableItem"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SelectDefaultLocation"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="NavigationServices"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SupportPackages"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Title"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="NavigationServices"
		#tag EndViewProperty
		#tag ViewProperty
			Name="UseCustomFrame"
			Group="Behavior"
			InitialValue="true"
			Type="Boolean"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
		#tag ViewProperty
			Name="WindowTitle"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="NavigationDialog"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
