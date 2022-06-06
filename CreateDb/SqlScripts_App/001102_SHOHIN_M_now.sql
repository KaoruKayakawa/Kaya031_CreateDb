USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SHOHIN_M_now]') AND type in (N'U'))
DROP TABLE [dbo].[SHOHIN_M_now]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SHOHIN_M_now](
	[SHM_HTCD] [int] NOT NULL,
	[SHM_SCD] [bigint] NOT NULL,
	[SHM_TEKIYOYMD] [datetime] NOT NULL,
	[SHM_UPDATECNT] [int] NOT NULL,
	[SHM_JANCD] [varchar](20) NULL,
	[SHM_BUMONCD] [smallint] NULL,
	[SHM_BURUICD] [int] NULL,
	[SHM_SHONAME] [nvarchar](100) NOT NULL,
	[SHM_MAKNAME] [varchar](30) NULL,
	[SHM_KIKNAME] [varchar](15) NULL,
	[SHM_SURYOSEIGEN] [smallint] NOT NULL,
	[SHM_TANKA] [int] NOT NULL,
	[SHM_YOUKIKBN] [tinyint] NULL,
	[SHM_JUNOUKIKAN] [tinyint] NOT NULL,
	[SHM_JUCHUSTR] [datetime] NOT NULL,
	[SHM_JUCHUEND] [datetime] NOT NULL,
	[SHM_HAISTR] [datetime] NOT NULL,
	[SHM_HAIEND] [datetime] NOT NULL,
	[SHM_HAITEISTR] [datetime] NOT NULL,
	[SHM_HAITEIEND] [datetime] NOT NULL,
	[SHM_KEISAIJYUN] [int] NOT NULL,
	[SHM_YOUBIKBN] [varchar](7) NULL,
	[SHM_URIZEIKBN] [tinyint] NOT NULL,
	[SHM_SFILENAME] [varchar](30) NULL,
	[SHM_KEISAIFLG] [tinyint] NOT NULL,
	[SHM_FAVBTNDFLG] [tinyint] NULL,
	[SHM_TYUKNRFLG] [tinyint] NULL,
	[SHM_SJKBN] [int] NOT NULL,
	[SHM_SEBANGO] [varchar](20) NULL,
	[SHM_ZAIKO] [int] NULL,
	[SHM_KEYWORD] [varchar](200) NULL,
	[SHM_NEWSORTKEY] [int] NULL,
	[SHM_SIMETIME] [datetime] NULL,
	[SHM_DISPPERIODSTR] [datetime] NULL,
	[SHM_DISPPERIODEND] [datetime] NULL,
	[SHM_TAXKBN] [tinyint] NOT NULL,
	[SHM_COMMENTDISPFLG] [bit] NOT NULL,
	[SHM_100BAIKA] [int] NULL,
	[SHM_MAXGRAM] [int] NULL,
	[SHM_MINGRAM] [int] NULL,
	[SHM_FUTEIKANKBN] [tinyint] NULL,
	[SHM_DELFG] [tinyint] NOT NULL,
	[SHM_INYMD] [datetime] NOT NULL,
	[SHM_INTANTO] [varchar](100) NOT NULL,
	[SHM_KOSINYMD] [datetime] NOT NULL,
	[SHM_KOSINTANTO] [varchar](100) NOT NULL,
 CONSTRAINT [PK_SHOHIN_M_now] PRIMARY KEY CLUSTERED 
(
	[SHM_HTCD] ASC,
	[SHM_SCD] ASC,
	[SHM_TEKIYOYMD] ASC,
	[SHM_UPDATECNT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
