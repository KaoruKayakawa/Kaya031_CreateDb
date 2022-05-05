USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CSV_SOURYOU]') AND type in (N'U'))
DROP TABLE [dbo].[CSV_SOURYOU]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CSV_SOURYOU](
	[CSO_KCD] [int] NOT NULL,
	[CSO_TENCD] [int] NOT NULL,
	[CSO_HANEIYMD] [datetime] NULL,
	[CSO_TEKIYOYMD] [datetime] NOT NULL,
	[CSO_SCD] [bigint] NOT NULL,
	[CSO_STR] [datetime] NOT NULL,
	[CSO_END] [datetime] NOT NULL,
	[CSO_SOURYO] [int] NOT NULL,
	[CSO_YDELKBN] [int] NOT NULL,
	[CSO_MDELKBN] [int] NOT NULL,
	[CSO_KOSINYMD] [datetime] NOT NULL,
	[CSO_YOBI1] [int] NULL,
	[CSO_YOBI2] [int] NULL,
	[CSO_YOBI3] [int] NULL,
	[CSO_YOBI4] [varchar](100) NULL,
	[CSO_YOBI5] [varchar](100) NULL,
	[CSO_YOBI6] [varchar](100) NULL,
	[CSO_YOBI7] [datetime] NULL,
	[CSO_YOBI8] [datetime] NULL,
	[CSO_YOBI9] [datetime] NULL,
	[CSO_IMPORTYMD] [datetime] NOT NULL,
	[CSO_IMPORTFILE] [varchar](100) NOT NULL,
 CONSTRAINT [PK_CSV_SOURYOU] PRIMARY KEY CLUSTERED 
(
	[CSO_KCD] ASC,
	[CSO_TENCD] ASC,
	[CSO_TEKIYOYMD] ASC,
	[CSO_SCD] ASC,
	[CSO_STR] ASC,
	[CSO_END] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
