USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_APP_CATSHN_MST]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_APP_CATSHN_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ft_APP_CATSHN_MST]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM APP_CATSHN_MST_now a
	INNER JOIN (
		SELECT SCSM_KCD, SCSM_HTCD, SCSM_LCATCD, SCSM_MCATCD, SCSM_SCATCD, SCSM_SCD, MAX(SCSM_TEKIYOYMD) AS SCSM_TEKIYOYMD
		FROM APP_CATSHN_MST_now
		WHERE SCSM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND SCSM_DELFG <> 1
		GROUP BY SCSM_KCD, SCSM_HTCD, SCSM_LCATCD, SCSM_MCATCD, SCSM_SCATCD, SCSM_SCD) b
	ON a.SCSM_KCD = b.SCSM_KCD
		AND a.SCSM_HTCD = b.SCSM_HTCD
		AND a.SCSM_LCATCD = b.SCSM_LCATCD
		AND a.SCSM_MCATCD = b.SCSM_MCATCD
		AND a.SCSM_SCATCD = b.SCSM_SCATCD
		AND a.SCSM_SCD = b.SCSM_SCD
		AND a.SCSM_TEKIYOYMD = b.SCSM_TEKIYOYMD
	WHERE a.SCSM_DELFG = 0
)
GO
