Imports System.IO
Imports System.Xml

Imports Microsoft.Data.SqlClient
Imports Microsoft.SqlServer.Management.Common

Module Module1

    Sub Main()
        Console.WriteLine("DB オブジェクト 作成")
        Console.WriteLine("")

        Console.WriteLine("▽ [識別名] を入力してください。 ▽")

        Dim objNm As String = Console.ReadLine()
        Dim objNd As XmlNode = SettingConfig.SqlScript_Folder(objNm)
        If objNd Is Nothing Then
            Console.WriteLine("　>> [識別名] は未設定です。")
            Console.WriteLine("")
            Console.WriteLine("…　処理を終了しました。")
            Console.WriteLine("")
            Console.WriteLine("…… Press [enter] key to exit.")
            Console.ReadLine()

            Return
        End If
        Dim wordRep As List(Of String()) = SettingConfig.SqlScript_Folder_Replace(objNd)

        Console.WriteLine("")
        Console.WriteLine("■ SQL スクリプトの実行中　…")

        Dim di As DirectoryInfo = New DirectoryInfo(SettingConfig.SqlScript_FolderPath(objNd) + "\db_create_drop")
        If Not di.Exists Then
            Console.WriteLine("　>> エラー：ＤＢ 作成・削除 スクリプト フォルダが見つかりません。")
            Console.WriteLine("")
            Console.WriteLine("…　処理は中止されました。")
            Console.WriteLine("")
            Console.WriteLine("…… Press [enter] key to exit.")
            Console.ReadLine()

            Return
        End If

        Dim fi_create As FileInfo() = di.GetFiles("Create.sql")
        If fi_create.Length = 0 Then
            Console.WriteLine("　>> エラー：ＤＢ作成スクリプトが見つかりません。")
            Console.WriteLine("")
            Console.WriteLine("…　処理は中止されました。")
            Console.WriteLine("")
            Console.WriteLine("…… Press [enter] key to exit.")
            Console.ReadLine()

            Return
        End If

        Dim fi_drop As FileInfo() = di.GetFiles("Drop.sql")
        If fi_drop.Length = 0 Then
            Console.WriteLine("　>> エラー：ＤＢ削除スクリプトが見つかりません。")
            Console.WriteLine("")
            Console.WriteLine("…　処理は中止されました。")
            Console.WriteLine("")
            Console.WriteLine("…… Press [enter] key to exit.")
            Console.ReadLine()

            Return
        End If

        Dim srvObj As ServerConnection = New ServerConnection(New SqlConnection(SettingConfig.SqlScript_Folder_ConStr(objNd)))

        Try
            db_EXE_QUERY.ExecuteQuery_01(fi_create(0).FullName, srvObj, wordRep)
        Catch ex As Exception
            Console.WriteLine("　>> エラー：" + ex.Message)
            Console.WriteLine("")
            Console.WriteLine("…　処理は中止されました。")
            Console.WriteLine("")
            Console.WriteLine("…… Press [enter] key to exit.")
            Console.ReadLine()

            Return
        End Try

        Dim ls As List(Of String) = New List(Of String)(Directory.GetFiles(SettingConfig.SqlScript_FolderPath(objNd)))
        ls.Sort(New Compare_LogicalString())

        Try
            srvObj.BeginTransaction()

            For Each fp As String In ls
                db_EXE_QUERY.ExecuteQuery_01(fp, srvObj, wordRep)
            Next

            srvObj.CommitTransaction()
        Catch ex As Exception
            srvObj.RollBackTransaction()

            Console.WriteLine("　>> エラー：" + ex.Message)
            Console.WriteLine("")
            Console.WriteLine("…　処理は中止されました。")

            Try
                db_EXE_QUERY.ExecuteQuery_01(fi_drop(0).FullName, srvObj, wordRep)
            Catch
                Console.WriteLine("…　　>> エラー：作成途中のＤＢを、削除できませんでした。手動で削除してください。")
            End Try

            Console.WriteLine("")
            Console.WriteLine("…… Press [enter] key to exit.")
            Console.ReadLine()

            Return
        End Try

        Console.WriteLine("")
        Console.WriteLine("…　処理が正常に終了しました。")
        Console.WriteLine("")
        Console.WriteLine("…… Press [enter] key to exit.")
        Console.ReadLine()

    End Sub

End Module
