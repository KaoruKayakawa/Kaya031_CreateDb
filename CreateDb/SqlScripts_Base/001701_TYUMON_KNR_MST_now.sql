USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TYUMON_KNR_MST_now]') AND type in (N'U'))
DROP TABLE [dbo].[TYUMON_KNR_MST_now]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TYUMON_KNR_MST_now](
	[STKF_KCD] [int] NOT NULL,
	[STKF_HTCD] [int] NOT NULL,
	[STKF_KIKAKUCD] [bigint] NOT NULL,
	[STKF_KIKAKUKBN] [int] NULL,
	[STKF_SCD] [bigint] NOT NULL,
	[STKF_STR] [datetime] NOT NULL,
	[STKF_END] [datetime] NOT NULL,
	[STKF_TEKIYOYMD] [datetime] NOT NULL,
	[STKF_UPDATECNT] [int] NOT NULL,
	[STKF_HANEIYMD] [datetime] NULL,
	[STKF_SOURYO] [int] NOT NULL,
	[STKF_NOWSURYO] [int] NOT NULL,
	[STKF_SESSIONID] [varchar](30) NULL,
	[STKF_YDELKBN] [int] NOT NULL,
	[STKF_MDELKBN] [int] NOT NULL,
	[STKF_YOBI1] [int] NULL,
	[STKF_YOBI2] [int] NULL,
	[STKF_YOBI3] [int] NULL,
	[STKF_YOBI4] [varchar](100) NULL,
	[STKF_YOBI5] [varchar](100) NULL,
	[STKF_YOBI6] [varchar](100) NULL,
	[STKF_YOBI7] [datetime] NULL,
	[STKF_YOBI8] [datetime] NULL,
	[STKF_YOBI9] [datetime] NULL,
	[STKF_IMPORTYMD] [datetime] NOT NULL,
	[STKF_IMPORTFILE] [varchar](100) NOT NULL,
	[STKF_DELFG] [tinyint] NOT NULL,
	[STKF_INYMD] [datetime] NOT NULL,
	[STKF_INTANTO] [varchar](100) NOT NULL,
	[STKF_KOSINYMD] [datetime] NOT NULL,
	[STKF_KOSINTANTO] [varchar](100) NOT NULL,
 CONSTRAINT [PK_TYUMON_KNR_MST_now] PRIMARY KEY CLUSTERED 
(
	[STKF_KCD] ASC,
	[STKF_HTCD] ASC,
	[STKF_SCD] ASC,
	[STKF_KIKAKUCD] ASC,
	[STKF_TEKIYOYMD] ASC,
	[STKF_UPDATECNT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
