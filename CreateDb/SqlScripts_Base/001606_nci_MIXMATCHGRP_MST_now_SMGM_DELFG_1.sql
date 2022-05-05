USE [#{-BASE_DB-}#]
GO

DROP INDEX IF EXISTS [nci_MIXMATCHGRP_MST_now_SMGM_DELFG_1] ON [dbo].[MIXMATCHGRP_MST_now]
GO

CREATE NONCLUSTERED INDEX [nci_MIXMATCHGRP_MST_now_SMGM_DELFG_1] ON [dbo].[MIXMATCHGRP_MST_now]
(
	[SMGM_DELFG] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
