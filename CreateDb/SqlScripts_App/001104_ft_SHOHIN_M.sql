USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_SHOHIN_M]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_SHOHIN_M]
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
CREATE FUNCTION [dbo].[ft_SHOHIN_M]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM SHOHIN_M_now a
	INNER JOIN (
		SELECT SHM_HTCD, SHM_SCD, MAX(SHM_TEKIYOYMD) AS SHM_TEKIYOYMD
		FROM SHOHIN_M_now
		WHERE SHM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND SHM_DELFG <> 1
		GROUP BY SHM_HTCD, SHM_SCD) b
	ON a.SHM_HTCD = b.SHM_HTCD
		AND a.SHM_SCD = b.SHM_SCD
		AND a.SHM_TEKIYOYMD = b.SHM_TEKIYOYMD
	WHERE a.SHM_DELFG = 0
)
GO
