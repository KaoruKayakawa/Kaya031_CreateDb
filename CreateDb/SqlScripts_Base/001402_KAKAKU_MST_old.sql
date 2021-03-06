USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KAKAKU_MST_old]') AND type in (N'U'))
DROP TABLE [dbo].[KAKAKU_MST_old]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[KAKAKU_MST_old](
	[SKAK_KCD] [int] NOT NULL,
	[SKAK_HTCD] [int] NOT NULL,
	[SKAK_SCD] [bigint] NOT NULL,
	[SKAK_TOKUSTR] [datetime] NOT NULL,
	[SKAK_TOKUEND] [datetime] NOT NULL,
	[SKAK_TEKIYOYMD] [datetime] NOT NULL,
	[SKAK_UPDATECNT] [int] NOT NULL,
	[SKAK_HANEIYMD] [datetime] NULL,
	[SKAK_KIKAKUCD] [bigint] NOT NULL,
	[SKAK_KIKAKUKBN] [int] NULL,
	[SKAK_TOKUKBN] [int] NOT NULL,
	[SKAK_TOKUGENKA] [float] NOT NULL,
	[SKAK_TOKUTANKA] [int] NOT NULL,
	[SKAK_TSURYOSEIGEN] [smallint] NOT NULL,
	[SKAK_TOKUKEISAIJUN] [int] NOT NULL,
	[SKAK_MAXBAIKA] [int] NULL,
	[SKAK_100BAIKA] [int] NULL,
	[SKAK_MINBAIKA] [int] NULL,
	[SKAK_SURYOSEIGEN] [smallint] NULL,
	[SKAK_SEIGYOKBN] [smallint] NULL,
	[SKAK_TEISHIKBN] [smallint] NULL,
	[SKAK_TOKUSJKBN] [int] NOT NULL,
	[SKAK_TYUKNRFLG] [tinyint] NULL,
	[SKAK_MCHKKBN] [tinyint] NULL,
	[SKAK_YDELKBN] [int] NOT NULL,
	[SKAK_MDELKBN] [int] NOT NULL,
	[SKAK_YOBI1] [int] NULL,
	[SKAK_YOBI2] [int] NULL,
	[SKAK_YOBI3] [int] NULL,
	[SKAK_YOBI4] [varchar](100) NULL,
	[SKAK_YOBI5] [varchar](100) NULL,
	[SKAK_YOBI6] [varchar](100) NULL,
	[SKAK_YOBI7] [datetime] NULL,
	[SKAK_YOBI8] [datetime] NULL,
	[SKAK_YOBI9] [datetime] NULL,
	[SKAK_IMPORTYMD] [datetime] NOT NULL,
	[SKAK_IMPORTFILE] [varchar](100) NOT NULL,
	[SKAK_KEISAI_OVERRIDE] [int] NULL,
	[SKAK_DELFG] [tinyint] NOT NULL,
	[SKAK_INYMD] [datetime] NOT NULL,
	[SKAK_INTANTO] [varchar](100) NOT NULL,
	[SKAK_KOSINYMD] [datetime] NOT NULL,
	[SKAK_KOSINTANTO] [varchar](100) NOT NULL,
 CONSTRAINT [PK_KAKAKU_MST_old] PRIMARY KEY CLUSTERED 
(
	[SKAK_KCD] ASC,
	[SKAK_HTCD] ASC,
	[SKAK_SCD] ASC,
	[SKAK_KIKAKUCD] ASC,
	[SKAK_TEKIYOYMD] ASC,
	[SKAK_UPDATECNT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
