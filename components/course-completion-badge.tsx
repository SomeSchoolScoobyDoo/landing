import Image from "next/image";

type CourseCompletionBadgeProps = {
  learnerName: string;
  courseTitle: string;
  issuedAt: string;
};

export function CourseCompletionBadge({
  learnerName,
  courseTitle,
  issuedAt,
}: CourseCompletionBadgeProps) {
  const date = new Date(issuedAt).toLocaleDateString("en-NG", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  return (
    <section
      className="kaizora-completion"
      aria-label={`Course completion badge for ${courseTitle}, awarded to ${learnerName}`}
    >
      <div className="kaizora-completion-content">
        <p className="kaizora-completion-wordmark">KAIZORA AI ACADEMY</p>

        <div className="kaizora-completion-course-wrap">
          <p className="kaizora-completion-kicker">COURSE COMPLETED</p>
          <h2 className="kaizora-completion-course">{courseTitle}</h2>
        </div>

        <div className="kaizora-completion-recipient">
          <p className="kaizora-completion-recipient-label">AWARDED TO</p>
          <p className="kaizora-completion-name">{learnerName}</p>
          <p className="kaizora-completion-date">ISSUED {date.toUpperCase()}</p>
        </div>

        <div className="kaizora-completion-signature" aria-hidden="true">
          <span />
          <Image src="/kaizora-logo.svg" alt="" width={22} height={27} />
          <span />
        </div>
      </div>

      <style>{`
        .kaizora-completion {
          width: 100%;
          max-width: 380px;
          aspect-ratio: 1 / 1;
          margin: 28px auto 12px;
          padding: 0;
          color: #493626;
          background: #f5efe3;
          text-align: center;
          overflow: hidden;
        }
        .kaizora-completion-content {
          width: 100%;
          height: 100%;
          min-height: 0;
          padding: clamp(22px, 5vw, 34px);
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: space-between;
        }
        .kaizora-completion-wordmark {
          margin: 0;
          color: #80694f;
          font: 700 9px/1.4 Arial, sans-serif;
          letter-spacing: 2px;
        }
        .kaizora-completion-course-wrap {
          width: 100%;
          display: flex;
          flex: 1;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          padding: 14px 0;
        }
        .kaizora-completion-kicker,
        .kaizora-completion-recipient-label {
          margin: 0 0 12px;
          color: #967b5d;
          font: 700 8px/1.4 Arial, sans-serif;
          letter-spacing: 1.8px;
        }
        .kaizora-completion-course {
          width: 100%;
          max-width: 310px;
          margin: 0;
          color: #493626;
          font: 500 clamp(22px, 4vw, 34px)/1.13 Georgia, "Times New Roman", serif;
          letter-spacing: -.65px;
          overflow-wrap: anywhere;
          text-wrap: balance;
        }
        .kaizora-completion-recipient {
          width: 100%;
          padding-bottom: 17px;
        }
        .kaizora-completion-recipient-label {
          margin-bottom: 5px;
          font-size: 7px;
          letter-spacing: 1.5px;
        }
        .kaizora-completion-name {
          max-width: 100%;
          margin: 0;
          color: #654d37;
          font: 500 clamp(14px, 2.4vw, 18px)/1.35 Georgia, "Times New Roman", serif;
          overflow-wrap: anywhere;
        }
        .kaizora-completion-date {
          margin: 8px 0 0;
          color: #927b62;
          font: 600 7px/1.4 Arial, sans-serif;
          letter-spacing: 1.2px;
        }
        .kaizora-completion-signature {
          width: 100%;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 12px;
        }
        .kaizora-completion-signature span {
          width: 54px;
          height: 1px;
          background: #b9a58b;
        }
        .kaizora-completion-signature img {
          width: 19px;
          height: 23px;
          object-fit: contain;
          flex: 0 0 auto;
        }
        @media (max-width: 420px) {
          .kaizora-completion-content { padding: 20px; }
          .kaizora-completion-course { font-size: clamp(20px, 6vw, 27px); }
          .kaizora-completion-signature span { width: 42px; }
        }
      `}</style>
    </section>
  );
}
