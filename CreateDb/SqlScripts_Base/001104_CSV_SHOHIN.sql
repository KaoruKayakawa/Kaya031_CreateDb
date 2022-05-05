USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CSV_SHOHIN]') AND type in (N'U'))
DROP TABLE [dbo].[CSV_SHOHIN]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CSV_SHOHIN](
	[CSH_KAICD] [int] NOT NULL,
	[CSH_TENCD] [int] NOT NULL,
	[CSH_TEKIYOYMD] [datetime] NOT NULL,
	[CSH_SCD] [bigint] NOT NULL,
	[CSH_JANCD1] [varchar](20) NOT NULL,
	[CSH_JANCD2] [varchar](20) NULL,
	[CSH_JANCD3] [varchar](20) NULL,
	[CSH_JANCD4] [varchar](20) NULL,
	[CSH_JANCD5] [varchar](20) NULL,
	[CSH_JANCD6] [varchar](20) NULL,
	[CSH_JANCD7] [varchar](20) NULL,
	[CSH_JANCD8] [varchar](20) NULL,
	[CSH_JANCD9] [varchar](20) NULL,
	[CSH_GAIHANSCD] [varchar](20) NULL,
	[CSH_BUMONCD] [smallint] NOT NULL,
	[CSH_BURUICD] [int] NULL,
	[CSH_SHONAME] [nvarchar](100) NOT NULL,
	[CSH_SURYOSEIGEN] [smallint] NULL,
	[CSH_SEIGYOKBN] [smallint] NULL,
	[CSH_TEISHIKBN] [smallint] NULL,
	[CSH_STANKA] [decimal](8, 2) NULL,
	[CSH_TANKA] [int] NOT NULL,
	[CSH_YOUKIKBN] [tinyint] NOT NULL,
	[CSH_JUNOUKIKAN] [tinyint] NULL,
	[CSH_JUCHUSTR] [datetime] NOT NULL,
	[CSH_JUCHUEND] [datetime] NOT NULL,
	[CSH_HAISTR] [datetime] NOT NULL,
	[CSH_HAIEND] [datetime] NOT NULL,
	[CSH_KEISAIJUN] [int] NOT NULL,
	[CSH_YOUBIKBN] [varchar](8) NOT NULL,
	[CSH_TOKUSHOKBN] [tinyint] NOT NULL,
	[CSH_RANK] [tinyint] NULL,
	[CSH_TANAGON] [smallint] NOT NULL,
	[CSH_TANADAN] [tinyint] NULL,
	[CSH_TANANARA] [tinyint] NULL,
	[CSH_TANAFACE] [tinyint] NULL,
	[CSH_URIZEIKBN] [tinyint] NOT NULL,
	[CSH_ZEIRITUKBN] [tinyint] NOT NULL,
	[CSH_SFILENAME] [varchar](30) NULL,
	[CSH_KEISAIKBN] [tinyint] NOT NULL,
	[CSH_FAVBTNKBN] [tinyint] NULL,
	[CSH_MYSHNKBN] [tinyint] NULL,
	[CSH_TYUKNRKBN] [tinyint] NULL,
	[CSH_SJKBN] [int] NULL,
	[CSH_SEBANGO] [varchar](20) NULL,
	[CSH_SIMETIME] [datetime] NULL,
	[CSH_OYASCD] [varchar](20) NULL,
	[CSH_FUTEIKANKBN] [tinyint] NOT NULL,
	[CSH_CHIRASHIKBN] [tinyint] NULL,
	[CSH_TOBASHIDISPKBN] [tinyint] NULL,
	[CSH_NOTSEARCHKBN] [tinyint] NULL,
	[CSH_SEARCHWORD] [varchar](200) NULL,
	[CSH_KENSACD] [int] NULL,
	[CSH_100BAIKA] [int] NULL,
	[CSH_MAXBAIKA] [int] NULL,
	[CSH_MINBAIKA] [int] NULL,
	[CSH_MAXGRAM] [int] NULL,
	[CSH_MINGRAM] [int] NULL,
	[CSH_NAIYO] [varchar](1000) NULL,
	[CSH_GENZAIRYO] [varchar](1000) NULL,
	[CSH_ALLERGEN] [varchar](500) NULL,
	[CSH_SEIBUN] [varchar](500) NULL,
	[CSH_YDELKBN] [int] NOT NULL,
	[CSH_MDELKBN] [int] NOT NULL,
	[CSH_KOSINYMD] [datetime] NOT NULL,
	[CSH_YOBI1] [int] NULL,
	[CSH_YOBI2] [int] NULL,
	[CSH_YOBI3] [int] NULL,
	[CSH_YOBI4] [varchar](100) NULL,
	[CSH_YOBI5] [varchar](100) NULL,
	[CSH_YOBI6] [varchar](100) NULL,
	[CSH_YOBI7] [datetime] NULL,
	[CSH_YOBI8] [datetime] NULL,
	[CSH_YOBI9] [datetime] NULL,
	[CSH_IMPORTYMD] [datetime] NOT NULL,
	[CSH_IMPORTFILE] [varchar](100) NOT NULL,
 CONSTRAINT [PK_CSV_SHOHIN] PRIMARY KEY CLUSTERED 
(
	[CSH_KAICD] ASC,
	[CSH_TENCD] ASC,
	[CSH_TEKIYOYMD] ASC,
	[CSH_SCD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
