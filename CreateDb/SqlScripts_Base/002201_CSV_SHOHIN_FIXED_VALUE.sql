USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CSV_SHOHIN_FIXED_VALUE]') AND type in (N'U'))
DROP TABLE [dbo].[CSV_SHOHIN_FIXED_VALUE]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CSV_SHOHIN_FIXED_VALUE](
	[SFV_KAICD] [int] NOT NULL,
	[SFV_TENSETNO] [int] NOT NULL,
	[SFV_SCD] [bigint] NOT NULL,
	[SFV_COL] [nvarchar](100) NOT NULL,
	[SFV_VAL] [sql_variant] NOT NULL,
	[SFV_SET_DT] [datetime] NOT NULL,
 CONSTRAINT [PK_CSV_SHOHIN_FIXED_VALUE] PRIMARY KEY CLUSTERED 
(
	[SFV_KAICD] ASC,
	[SFV_TENSETNO] ASC,
	[SFV_SCD] ASC,
	[SFV_COL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
