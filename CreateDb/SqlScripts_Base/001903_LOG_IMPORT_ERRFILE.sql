USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LOG_IMPORT_ERRFILE]') AND type in (N'U'))
DROP TABLE [dbo].[LOG_IMPORT_ERRFILE]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LOG_IMPORT_ERRFILE](
	[LIEF_FILENAME] [nvarchar](100) NOT NULL,
	[LIEF_LOGYMD] [datetime] NOT NULL,
	[LIEF_MSG] [nvarchar](500) NOT NULL,
 CONSTRAINT [PK_LOG_IMPORT_ERRFILE] PRIMARY KEY CLUSTERED 
(
	[LIEF_FILENAME] ASC,
	[LIEF_LOGYMD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO