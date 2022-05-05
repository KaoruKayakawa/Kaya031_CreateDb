Imports System.IO
Imports System.Text

Imports Microsoft.SqlServer.Management.Common

Public Class db_EXE_QUERY
    Public Shared Sub ExecuteQuery_01(fp As String, srvCon As ServerConnection, wordRep As List(Of String()))
        ' ファイルは UTF-8・Shift-JIS 何れかの前提
        Dim enc As Encoding = io_File.GetEncording(fp, New Integer() {932, 65001})
        If enc Is Nothing Then
            Throw New ApplicationException("SQL QUERY ファイルのエンコードが異なります。UTF-8・Shift-JIS のみ使用できます。")
        End If

        Dim script As String = Nothing
        Using sr As StreamReader = New StreamReader(fp, enc)
            script = sr.ReadToEnd()
        End Using

        For Each wordRep_ele As String() In wordRep
            script = script.Replace(wordRep_ele(0), wordRep_ele(1))
        Next

        Try
            srvCon.ExecuteNonQuery(script)
        Catch ex As Exception
            Dim msg As String = ex.InnerException.Message + "（ファイル：" + fp + "）"

            Throw New ApplicationException(msg, ex)
        End Try
    End Sub
End Class
