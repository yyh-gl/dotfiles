import type { Register } from 'claude-code'

// Step 1: 読み込み経路の検証用。帯が出るかどうかだけを確かめる
export const register: Register = on => {
  on('ui.render', { component: 'AbovePrompt' }, ($, e, next) => {
    if (e.props.hasSurvey) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box>
        <Text color="#769ff0">statusline mod loaded ({e.surface})</Text>
      </Box>
    )
  })
}
