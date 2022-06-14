USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_TYUMON_KNR_F]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_TYUMON_KNR_F]
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
CREATE FUNCTION [dbo].[ft_TYUMON_KNR_F]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM TYUMON_KNR_F_now a
	INNER JOIN (
		SELECT TKF_HTCD, TKF_SCD, TKF_KIKAKUCD, MAX(TKF_TEKIYOYMD) AS TKF_TEKIYOYMD
		FROM TYUMON_KNR_F_now
		WHERE TKF_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND TKF_DELFG <> 1
		GROUP BY TKF_HTCD, TKF_SCD, TKF_KIKAKUCD) b
	ON a.TKF_HTCD = b.TKF_HTCD
		AND a.TKF_SCD = b.TKF_SCD
		AND a.TKF_KIKAKUCD = b.TKF_KIKAKUCD
		AND a.TKF_TEKIYOYMD = b.TKF_TEKIYOYMD
	WHERE a.TKF_DELFG = 0
)
GO
