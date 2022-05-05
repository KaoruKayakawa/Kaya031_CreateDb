Imports System.IO
Imports System.Text

Public Class io_File
    ''' <summary>
    ''' 対象から、ファイルに適用可能なエンコーディングを取得する
    ''' </summary>
    ''' <param name="fp">ファイル パス</param>
    ''' <param name="ls_enc">適用対象のコードページ ID</param>
    ''' <returns>エンコーディング</returns>
    Public Shared Function GetEncording(fp As String, ls_enc As Integer()) As Encoding
        Dim enc As Encoding = Nothing, fc As String
        Dim bs1 As Byte() = File.ReadAllBytes(fp), bs2 As Byte(), idx As Integer

        For Each cd As Integer In ls_enc
            enc = Encoding.GetEncoding(cd)

            fc = enc.GetString(bs1)
            bs2 = enc.GetBytes(fc)

            If bs1.Length = bs2.Length Then
                For idx = 0 To bs1.Length - 1
                    If bs1(idx) <> bs2(idx) Then
                        Exit For
                    End If
                Next

                If idx = bs1.Length Then
                    Exit For
                End If
            End If

            enc = Nothing
        Next

        Return enc
    End Function
End Class
