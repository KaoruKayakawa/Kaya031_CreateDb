Imports System.Xml

Public Class SettingConfig
    Protected Shared _root As XmlNode

    Shared Sub New()
        Try
            Dim fn As String
            fn = System.Environment.CurrentDirectory + "\Setting.config"

            Dim doc As XmlDocument = New XmlDocument
            doc.Load(fn)

            _root = doc.SelectSingleNode("/configuration")
        Catch ex As Exception
            Throw New ApplicationException("Iregular Setting.config File.", ex)
        End Try
    End Sub

    Public Shared Function SqlScript_Folder(name As String) As XmlNode
        Return _root.SelectSingleNode(String.Format("./sql_script/folder[@name='{0}']", name))
    End Function

    Public Shared Function SqlScript_FolderPath(nd As XmlNode) As String
        Return nd.Attributes("path").Value
    End Function

    Public Shared Function SqlScript_Folder_ConStr(nd As XmlNode) As String
        Return nd.SelectSingleNode("./connstring").InnerText.Trim()
    End Function

    Public Shared Function SqlScript_Folder_Replace(nd As XmlNode) As List(Of String())
        Dim ls As List(Of String()) = New List(Of String())()

        For Each nd_ele As XmlNode In nd.SelectNodes("./replace/ele")
            Dim srcDest(1) As String
            srcDest(0) = nd_ele.Attributes("src").Value
            srcDest(1) = nd_ele.Attributes("dest").Value

            ls.Add(srcDest)
        Next

        Return ls
    End Function

End Class
