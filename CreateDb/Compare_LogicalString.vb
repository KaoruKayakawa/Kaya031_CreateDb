Imports System.Runtime.InteropServices

Public Class Compare_LogicalString
    Implements IComparer
    Implements IComparer(Of String)

    <DllImport("shlwapi.dll", CharSet:=System.Runtime.InteropServices.CharSet.Unicode, ExactSpelling:=True)>
    Private Shared Function StrCmpLogicalW(x As String, y As String) As Integer
    End Function

    Public Function Compare(a As String, b As String) As Integer Implements IComparer(Of String).Compare
        Return StrCmpLogicalW(a, b)
    End Function

    Public Function Compare(a As Object, b As Object) As Integer Implements IComparer.Compare
        Return Compare(a.ToString(), b.ToString())
    End Function
End Class
