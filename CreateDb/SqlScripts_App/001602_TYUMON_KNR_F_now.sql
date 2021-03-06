USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TYUMON_KNR_F_now]') AND type in (N'U'))
DROP TABLE [dbo].[TYUMON_KNR_F_now]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TYUMON_KNR_F_now](
	[TKF_HTCD] [int] NOT NULL,
	[TKF_KIKAKUCD] [bigint] NOT NULL,
	[TKF_KIKAKUKBN] [int] NULL,
	[TKF_SCD] [bigint] NOT NULL,
	[TKF_STR] [datetime] NOT NULL,
	[TKF_END] [datetime] NOT NULL,
	[TKF_TEKIYOYMD] [datetime] NOT NULL,
	[TKF_UPDATECNT] [int] NOT NULL,
	[TKF_SOURYO] [int] NOT NULL,
	[TKF_NOWSURYO] [int] NOT NULL,
	[TKF_SESSIONID] [varchar](30) NULL,
	[TKF_DELFG] [tinyint] NOT NULL,
	[TKF_INYMD] [datetime] NOT NULL,
	[TKF_INTANTO] [varchar](100) NOT NULL,
	[TKF_KOSINYMD] [datetime] NOT NULL,
	[TKF_KOSINTANTO] [varchar](100) NOT NULL,
 CONSTRAINT [PK_TYUMON_KNR_F_now] PRIMARY KEY CLUSTERED 
(
	[TKF_HTCD] ASC,
	[TKF_SCD] ASC,
	[TKF_KIKAKUCD] ASC,
	[TKF_TEKIYOYMD] ASC,
	[TKF_UPDATECNT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
