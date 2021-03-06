USE [#{-BASE_DB-}#]
GO

DROP INDEX IF EXISTS [nci_TYUMON_KNR_MST_now_STKF_KOSINYMD_1] ON [dbo].[TYUMON_KNR_MST_now]
GO

CREATE NONCLUSTERED INDEX [nci_TYUMON_KNR_MST_now_STKF_KOSINYMD_1] ON [dbo].[TYUMON_KNR_MST_now]
(
	[STKF_KOSINYMD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
