package mail

import (
	"testing"

	"github.com/PetrusZ/simplebank/util"
	"github.com/stretchr/testify/require"
)

func TestSendEmailWithGmail(t *testing.T) {
	config, err := util.LoadConfig("..")
	require.NoError(t, err)

	sender := NewGmailSender(config.EmailSenderName, config.EmailSenderAddress, config.EmailSenderPassword)

	subject := "A test email"
	content := `
	<h1>Hello world</h1>
	<p>This is a test message from <a href="https://www.codeplayer.org">codeplayer.org</a></p>
	`

	to := []string{"patrick.zhao.07@gmail.com"}
	attach := []string{"../README.md"}

	err = sender.SendEmail(subject, content, to, nil, nil, attach)
	require.NoError(t, err)
}
