import SwiftUI
import MessageUI

struct ExportOptionsView: View {
    let records: [InspectionRecord]
    var onDismiss: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var pendingExport: PendingExport?
    @State private var fallbackURLs: [URL] = []
    @State private var showingMail = false
    @State private var showingShare = false
    @State private var infoMessage: String?

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        let dates = records.map(\.timestamp).sorted()
        guard let first = dates.first, let last = dates.last else { return "" }
        if Calendar.current.isDate(first, inSameDayAs: last) {
            return formatter.string(from: first)
        }
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }

    var body: some View {
        Form {
            Section("Selected") {
                LabeledContent("Records", value: "\(records.count)")
                if !dateRangeText.isEmpty {
                    LabeledContent("Date range", value: dateRangeText)
                }
                LabeledContent("To", value: settings.defaultEmail)
            }

            Section {
                Button {
                    exportList()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Export List (CSV)").font(.headline)
                            Text("Summary table of selected records.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "tablecells")
                    }
                }
                .buttonStyle(.plain)

                Button {
                    exportWithPhotos()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Export with Photos (PDF)").font(.headline)
                            Text("One PDF per record with photos rendered inline.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "doc.richtext")
                    }
                }
                .buttonStyle(.plain)
            }

            if let infoMessage {
                Section {
                    Text(infoMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onDismiss() }
            }
        }
        .sheet(isPresented: $showingMail) {
            if let pendingExport {
                MailComposeView(
                    recipients: pendingExport.recipients,
                    subject: pendingExport.subject,
                    body: pendingExport.body,
                    attachments: pendingExport.attachments
                ) { _ in
                    showingMail = false
                    onDismiss()
                }
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showingShare) {
            ShareSheetView(itemURLs: fallbackURLs) {
                showingShare = false
                onDismiss()
            }
            .ignoresSafeArea()
        }
    }

    private func exportList() {
        let data = CSVExporter.build(records: records)
        let attachment = PDFExporter.Attachment(
            data: data,
            mimeType: "text/csv",
            filename: CSVExporter.suggestedFilename(count: records.count)
        )
        present(
            attachments: [attachment],
            subject: "W&M Inspection List – \(records.count) records",
            body: "Attached: CSV summary of \(records.count) inspection record(s)."
        )
    }

    private func exportWithPhotos() {
        let attachments = PDFExporter.buildAttachments(
            records: records,
            includeOriginalPhotos: settings.attachOriginalPhotos
        )
        present(
            attachments: attachments,
            subject: "W&M Inspection Details – \(records.count) records",
            body: "Attached: detailed PDF report(s)\(settings.attachOriginalPhotos ? " plus original photos" : "")."
        )
    }

    private func present(attachments: [PDFExporter.Attachment], subject: String, body: String) {
        let recipients = settings.defaultEmail.trimmingCharacters(in: .whitespaces).isEmpty
            ? []
            : [settings.defaultEmail]
        pendingExport = PendingExport(
            recipients: recipients,
            subject: subject,
            body: body,
            attachments: attachments
        )

        if EmailComposer.canSendMail() {
            showingMail = true
        } else {
            fallbackURLs = EmailComposer.writeAttachmentsToTempDirectory(attachments)
            if fallbackURLs.isEmpty {
                infoMessage = "Mail isn't configured and the share sheet couldn't be prepared."
            } else {
                infoMessage = "Mail isn't configured on this device. Use the share sheet to send."
                showingShare = true
            }
        }
    }
}
