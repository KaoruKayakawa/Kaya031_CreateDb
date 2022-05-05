USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_SHOHIN_MST]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_SHOHIN_MST]
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
CREATE FUNCTION [dbo].[ft_SHOHIN_MST]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM SHOHIN_MST_now a
	INNER JOIN (
		SELECT SSHM_KCD, SSHM_HTCD, SSHM_SCD, MAX(SSHM_TEKIYOYMD) AS SSHM_TEKIYOYMD
		FROM SHOHIN_MST_now
		WHERE SSHM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND SSHM_DELFG <> 1
		GROUP BY SSHM_KCD, SSHM_HTCD, SSHM_SCD) b
	ON a.SSHM_KCD = b.SSHM_KCD
		AND a.SSHM_HTCD = b.SSHM_HTCD
		AND a.SSHM_SCD = b.SSHM_SCD
		AND a.SSHM_TEKIYOYMD = b.SSHM_TEKIYOYMD
	WHERE a.SSHM_DELFG = 0
)
GO
