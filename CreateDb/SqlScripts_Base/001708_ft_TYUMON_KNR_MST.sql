USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_TYUMON_KNR_MST]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_TYUMON_KNR_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		kayakawa
-- Create date:
-- Description:	
-- =============================================
CREATE FUNCTION [dbo].[ft_TYUMON_KNR_MST]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM TYUMON_KNR_MST_now a
	INNER JOIN (
		SELECT STKF_KCD, STKF_HTCD, STKF_SCD, STKF_KIKAKUCD, MAX(STKF_TEKIYOYMD) AS STKF_TEKIYOYMD
		FROM TYUMON_KNR_MST_now
		WHERE STKF_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND STKF_DELFG <> 1
		GROUP BY STKF_KCD, STKF_HTCD, STKF_SCD, STKF_KIKAKUCD) b
	ON a.STKF_KCD = b.STKF_KCD
		AND a.STKF_HTCD = b.STKF_HTCD
		AND a.STKF_SCD = b.STKF_SCD
		AND a.STKF_KIKAKUCD = b.STKF_KIKAKUCD
		AND a.STKF_TEKIYOYMD = b.STKF_TEKIYOYMD
	WHERE a.STKF_DELFG = 0
)
GO
